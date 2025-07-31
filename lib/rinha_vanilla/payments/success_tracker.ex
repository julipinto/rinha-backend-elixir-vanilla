defmodule RinhaVanilla.Payments.SuccessTracker do
  alias RinhaVanilla.PriorityQueueCache

  @key_prefix "processed_payments:"
  def track(processor_atom, %{"amount_in_cents" => amount, "correlation_id" => corr_id}) do
    timestamp = DateTime.utc_now() |> DateTime.to_unix()
    key = "#{@key_prefix}#{processor_atom}"

    member_payload = Jason.encode!(%{
      correlation_id: corr_id,
      amount_in_cents: amount
    })

    PriorityQueueCache.zadd(key, member_payload, timestamp)
  end
end