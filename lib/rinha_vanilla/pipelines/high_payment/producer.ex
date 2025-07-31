defmodule RinhaVanilla.Pipelines.HighPayment.ListProducer do
  use GenStage
  @behaviour Broadway.Producer

  alias Broadway.Message
  alias RinhaVanilla.Cache.LineCache

  require Logger

  @timer_interval_ms 200

  def init(opts) do
    queue_key = Keyword.fetch!(opts, :queue_key)
    state = %{queue_key: queue_key, demand: 0}
    Process.send_after(self(), :poll, @timer_interval_ms)
    {:producer, state}
  end

  def handle_demand(incoming_demand, state) do
    {:noreply, [], %{state | demand: state.demand + incoming_demand}}
  end

  def handle_info(:poll, %{demand: demand, queue_key: key} = state) when demand > 0 do
    Process.send_after(self(), :poll, @timer_interval_ms)

    events = LineCache.rpop(key, demand)

    messages =
      Enum.map(events, fn payload ->
        %Message{data: payload, acknowledger: {Broadway.NoopAcknowledger, nil, nil}}
      end)

    {:noreply, messages, %{state | demand: state.demand - length(messages)}}
  end

  def handle_info(:poll, state) do
    Process.send_after(self(), :poll, @timer_interval_ms)
    {:noreply, [], state}
  end
end
