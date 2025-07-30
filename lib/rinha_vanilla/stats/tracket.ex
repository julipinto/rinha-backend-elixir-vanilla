defmodule RinhaVanilla.Stats.Tracker do
  @stats_key "payments_processed_stats"
  
  alias RinhaVanilla.PriorityQueueCache
  alias RinhaVanilla.Cache

  @doc """
  Register the value of a successful payment in a Sorted Set for analysis.
  """
  def track_payment(amount_in_cents, correlation_id) do
    # We are using an sorted set to keep the values ordered.
    # The member needs to be unique, so the correlation_id is perfect.
    PriorityQueueCache.zadd(@stats_key, correlation_id, amount_in_cents)
  end

  def range_payments(index) do
    PriorityQueueCache.zrange_with_scores(@stats_key, index, index)
  end

  def total_payments_count do
    PriorityQueueCache.zcard(@stats_key)
  end

  def get_high_value_threshold do
    Cache.get(@stats_key)
  end
end