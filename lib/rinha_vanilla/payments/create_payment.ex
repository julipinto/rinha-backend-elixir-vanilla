defmodule RinhaVanilla.Payments.CreatePayment do
  alias RinhaVanilla.PriorityQueueCache
  alias RinhaVanilla.Types.CreatePaymentType
  alias RinhaVanilla.Cache.LineCache

  alias RinhaVanilla.Payments.PaymentQueueRouter

  def enqueue(%CreatePaymentType{} = payment_attrs) do
    {:ok, payload} = payment_attrs |> Map.from_struct() |> Jason.encode()

    case PaymentQueueRouter.route(payment_attrs) do
      {:high_value, queue} ->
        LineCache.ladd(queue, payload)
        {:ok, :enqueued_high_value}

      {:standard, queue} ->
        score_in_float = payment_attrs.amount_in_cents / 1.0
        PriorityQueueCache.zadd(queue, payload, score_in_float)
        {:ok, :enqueued_standard}
    end
  end

  def get_summary() do
    # TODO: Implementar a busca e agregação no Redis.
    # Por enquanto, vamos retornar um valor fixo.
    {:ok, %{default: %{totalRequests: 0, totalAmount: 0.0}}}
  end
end
