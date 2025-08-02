defmodule RinhaVanilla.Pipelines.HighPayment.Pipeline do
  use Broadway

  require Logger

  alias Broadway.Message
  alias RinhaVanilla.Integrations.ProcessorIntegrations
  alias RinhaVanilla.Integrations.Types.PaymentType
  alias RinhaVanilla.Pipelines.HighPayment.ListProducer
  alias RinhaVanilla.Cache.LineCache
  alias RinhaVanilla.Payments.SuccessTracker
  alias RinhaVanilla.Health.HealthCache

  @max_retries 3
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
    with {:ok, data} <- Jason.decode(message.data),
         %{"amount_in_cents" => amount, "correlation_id" => corr_id, "requested_at" => req_at} =
           data do
      chosen_processor = :default

      integration_payload =
        PaymentType.transform_amount(chosen_processor, %{
          amount_in_cents: amount,
          correlation_id: corr_id,
          requested_at: req_at
        })

      case ProcessorIntegrations.process_payment(integration_payload) do
        {:ok, _response} ->
          SuccessTracker.track(chosen_processor, data)
          message

        {:error, _reason} ->
          HealthCache.report_failure(chosen_processor)
          Message.failed(message, "processor_error")
      end
    else
      _error ->
        Message.failed(message, "invalid_payload")
    end
  end

  @impl true
  def handle_failed(messages, _context) do
    messages_to_retry =
      Enum.map(messages, fn message ->
        {:ok, data} = Jason.decode(message.data)
        retry_count = Map.get(data, "retry_count", 0) + 1

        if retry_count > @max_retries do
          Logger.error("High-value payment discarded after max retries: #{inspect(data)}")
          :discard
        else
          Map.put(data, "retry_count", retry_count)
        end
      end)
      |> Enum.reject(&(&1 == :discard))

    unless Enum.empty?(messages_to_retry) do
      Enum.each(messages_to_retry, fn payload_map ->
        {:ok, payload_str} = Jason.encode(payload_map)
        LineCache.ladd(@queue_key, payload_str)
      end)
    end

    messages
  end
end
