defmodule RinhaVanilla.Payments.StandardPayment.Pipeline do
  use Broadway

  require Logger

  alias Broadway.Message
  alias RinhaVanilla.Health.HealthCache
  alias RinhaVanilla.Integrations.ProcessorIntegrations
  alias RinhaVanilla.Integrations.Types.PaymentType
  alias RinhaVanilla.Pipelines.StandardPayment.Producer
  alias RinhaVanilla.PriorityQueueCache
  alias RinhaVanilla.Payments.SuccessTracker

  @max_retries 3
  @queue_key :payments_queue

  def start_link(_opts) do
    Broadway.start_link(__MODULE__,
      name: __MODULE__,
      producer: [
        module: {Producer, queue_key: @queue_key},
        concurrency: 1
      ],
      processors: [
        default: [
          concurrency: 2
        ]
      ]
    )
  end

  @impl true
  def handle_message(_processor, message, _context) do
    chosen_processor = HealthCache.preferred_processor()
    
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
        message.reason == :known_gateway_offline
      end)

    unless Enum.empty?(messages_to_requeue) do
      score_payloads =
        Enum.map(messages_to_requeue, fn message ->
          {:ok, data} = Jason.decode(message.data)
          score = Map.get(data, "amount_in_cents") / 1.0
          {score, message.data}
        end)

      # return to priority queue to wait for gateway recovery
      case PriorityQueueCache.bulk_zadd(@queue_key, score_payloads) do
        {:ok, _} ->
          Logger.info(
            "#{length(score_payloads)} payments re-queued to wait for gateway recovery."
          )

        {:error, reason} ->
          Logger.error("Failed to re-queue messages: #{inspect(reason)}")
      end
    end

    messages
  end
end
