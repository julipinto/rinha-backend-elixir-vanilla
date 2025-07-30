defmodule RinhaVanilla.Pipelines.Producer do
  use GenStage
  @behaviour Broadway.Producer

  alias Broadway.Message
  alias RinhaVanilla.PriorityQueueCache

  require Logger

  @timer_interval_ms 200

  @impl true
  def init(opts) do
    queue_key = Keyword.fetch!(opts, :queue_key)

    state = %{
      queue_key: queue_key,
      timer_interval_ms: @timer_interval_ms,
      demand: 0
    }

    schedule_poll(state.timer_interval_ms)

    {:producer, state}
  end

  @impl true
  def handle_demand(incoming_demand, state) do
    {:noreply, [], %{state | demand: state.demand + incoming_demand}}
  end

  @impl true
  def handle_info(:poll, %{demand: demand} = state) when demand > 0 do
    schedule_poll(state.timer_interval_ms)

    events = PriorityQueueCache.zpomax(state.queue_key, demand)

    messages =
      events
      |> Enum.map(fn payload ->
        %Message{
          data: payload,
          metadata: %{},
          acknowledger: {Broadway.NoopAcknowledger, nil, nil}
        }
      end)

    {:noreply, messages, %{state | demand: state.demand - length(messages)}}
  end

  @impl true
  def handle_info(:poll, state) do
    schedule_poll(state.timer_interval_ms)
    {:noreply, [], state}
  end

  defp schedule_poll(interval_ms) do
    Process.send_after(self(), :poll, interval_ms)
  end

  defp choose_fetch_strategy() do
    case RinhaVanilla.Health.Cache.preferred_processor() do
      :default -> :highest_first
      :fallback -> :lowest_first
      _ -> :lowest_first
    end
  end
end
