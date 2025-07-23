defmodule RinhaVanilla.Payments.CreatePayment do
  alias RinhaVanilla.PriorityQueueCache
  alias RinhaVanilla.Types.CreatePaymentType

  def enqueue(%CreatePaymentType{} = payment_attrs) do
    {:ok, payload} = payment_attrs |> Map.from_struct() |> Jason.encode()

    # We will use an score to prioritize payments
    score = payment_attrs.amount_in_cents / 1.0

    PriorityQueueCache.zadd(:payments_queue, payload, score)
  end

  def get_summary() do
    # TODO: Implementar a busca e agregação no Redis.
    # Por enquanto, vamos retornar um valor fixo.
    {:ok, %{default: %{totalRequests: 0, totalAmount: 0.0}}}
  end
end
