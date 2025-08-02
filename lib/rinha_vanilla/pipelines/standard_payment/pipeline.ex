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
    with {:ok, data} <- Jason.decode(message.data),
         %{"amount_in_cents" => amount, "correlation_id" => corr_id, "requested_at" => req_at} =
           data do
      chosen_processor = HealthCache.preferred_processor()

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
          Logger.error("Payment discarded after max retries: #{inspect(data)}")
          :discard
        else
          data_to_retry = Map.put(data, "retry_count", retry_count)
          score = Map.get(data_to_retry, "amount_in_cents")
          {:ok, payload} = Jason.encode(data_to_retry)
          {score, payload, message}
        end
      end)
      |> Enum.reject(&(&1 == :discard))

    if Enum.empty?(messages_to_retry) do
      messages
    else
      score_payloads =
        Enum.map(messages_to_retry, fn {score, payload, _msg} -> {score, payload} end)

      case PriorityQueueCache.bulk_zadd(@queue_key, score_payloads) do
        {:ok, :all_succeeded} ->
          messages

        {:error, failures} ->
          Logger.error("Some Redis ZADD operations failed: #{inspect(failures)}")

          failed_payloads =
            failures
            |> Enum.flat_map(fn {chunk, _reason} -> chunk end)
            |> MapSet.new(fn {_score, payload} -> payload end)

          Enum.filter(messages, fn msg -> MapSet.member?(failed_payloads, msg.data) end)
      end
    end
  end
end
