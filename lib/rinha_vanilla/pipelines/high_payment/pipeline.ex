defmodule RinhaVanilla.Pipelines.HighPayment.Pipeline do
  use Broadway

  require Logger

  alias Broadway.Message
  alias RinhaVanilla.Integrations.ProcessorIntegrations
  alias RinhaVanilla.Integrations.Types.PaymentType
  alias RinhaVanilla.Pipelines.HighPayment.ListProducer
  alias RinhaVanilla.Cache.RegularQueueCache
  alias RinhaVanilla.Payments.SuccessTracker
  alias RinhaVanilla.Health.HealthCache

  @queue_key :high_value_queue

  def start_link(_opts) do
    Broadway.start_link(__MODULE__,
      name: __MODULE__,
      producer: [
        module: {ListProducer, queue_key: @queue_key},
        concurrency: 1
      ],
      processors: [
        default: [
          concurrency: 150
        ]
      ]
    )
  end

  @impl true
  def handle_message(_processor, message, _context) do
    chosen_processor = :default

    with true <- HealthCache.is_processor_ok?(chosen_processor),
         {:ok, data} <- Jason.decode(message.data),
         integration_payload = PaymentType.transform_amount(chosen_processor, data),
         {:ok, _response} <- ProcessorIntegrations.process_payment(integration_payload),
         :ok <- track_with_retry(chosen_processor, data) do
      message
    else
      {:error, :known_gateway_offline} ->
        Message.failed(message, :known_gateway_offline)

      {:error, %Jason.DecodeError{} = data} ->
        Logger.error("Failed to decode JSON data: #{inspect(data)}")
        Message.failed(message, :invalid_payload)

      {:error, :max_retries_reached} ->
        Message.failed(message, :persistent_tracking_failure)

      {:error, _reason} ->
        HealthCache.report_failure(chosen_processor)
        Message.failed(message, :known_gateway_offline)

      _error ->
        Logger.error("Unexpected error processing message: #{inspect(message)}")
        Message.failed(message, :unknown_error)
    end
  end

  @impl true
  def handle_failed(messages, _context) do
    messages_to_requeue =
      Enum.filter(messages, fn message ->
        case message.status do
          {:failed, :known_gateway_offline} -> true
          _ -> false
        end
      end)

    unless Enum.empty?(messages_to_requeue) do
      Logger.info(
        "#{length(messages_to_requeue)} high-value payments re-queued to wait for default gateway."
      )

      Enum.each(messages_to_requeue, fn message ->
        RegularQueueCache.ladd(@queue_key, message.data)
      end)
    end

    messages
  end

  defp track_with_retry(chosen_processor, data, retries_left \\ 3)

  defp track_with_retry(_processor, data, 0) do
    inspect_data = inspect(data)

    Logger.critical("""
    PERSISTENT TRACKING FAILURE! Payment processed but could not be tracked after multiple retries.
    Manual intervention required for correlation_id: #{data["correlation_id"]}
    Data: #{inspect_data}
    """)

    {:error, :max_retries_reached}
  end

  defp track_with_retry(chosen_processor, data, retries_left) do
    case SuccessTracker.track(chosen_processor, data) do
      {:ok, _} ->
        :ok

      {:error, _reason} ->
        Process.sleep(100)
        track_with_retry(chosen_processor, data, retries_left - 1)
    end
  end
end
