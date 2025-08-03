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
          concurrency: 5
        ]
      ]
    )
  end

  @impl true
  def handle_message(_processor, message, _context) do
    chosen_processor = :default

    with {:ok, data} <- Jason.decode(message.data),
         true <- HealthCache.is_processor_ok?(chosen_processor) do
      integration_payload = PaymentType.transform_amount(chosen_processor, data)

      case ProcessorIntegrations.process_payment(integration_payload) do
        {:ok, _response} ->
          SuccessTracker.track(chosen_processor, data)
          message

        {:error, _reason} ->
          HealthCache.report_failure(chosen_processor)
          Message.failed(message, :known_gateway_offline)
      end
    else
      {:error, :known_gateway_offline} ->
        Message.failed(message, :known_gateway_offline)

      _error ->
        Message.failed(message, "invalid_payload")
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
end
