# lib/rinha_vanilla/stats/threshold_manager.ex

defmodule RinhaVanilla.Stats.ThresholdManager do
  use GenServer
  require Logger

  alias RinhaVanilla.Stats.Tracker
  alias RinhaVanilla.Cache

  @stats_key "payments_processed_stats"
  @threshold_cache_key "high_value_threshold_in_cents"
  @recalc_interval_ms 30_000
  @min_sample_size 50
  @percentile Application.get_env(:rinha_vanilla, :high_value_percentile, 0.8) # 80% = Top 20%

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  @impl true
  def init(state) do
    Logger.info("ThresholdManager started. Scheduling first calculation.")
    Process.send(self(), :recalculate_threshold, [])
    {:ok, state}
  end

  @impl true
  def handle_info(:recalculate_threshold, state) do
    {:ok, total_count_str} = Tracker.total_payments_count()
    total_count = String.to_integer(total_count_str)

    if total_count > @min_sample_size do
      index = round(total_count * @percentile)

      with {:ok, [_value, score_str]} <- Tracker.range_payments(index) do
        Cache.set(@threshold_cache_key, score_str)
        Logger.info("High-value payment threshold updated to: #{score_str} cents")
      end
    end

    Process.send_after(self(), :recalculate_threshold, @recalc_interval_ms)
    {:noreply, state}
  end
end