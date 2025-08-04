defmodule RinhaVanilla.Health.LeaderElector do
  @moduledoc """
  This GenServer ensures that only one node in the cluster becomes the leader
  to perform critical tasks, such as the HealthMonitor.
  """
  use GenServer

  alias RinhaVanilla.Cache

  require Logger

  @lock_key "health_check:leader_lock"
  # 10 seconds
  @lock_ttl_ms 10_000
  # 5 seconds
  @check_interval_ms 5_000

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  @impl true
  def init(_state) do
    # On start, we try to acquire the lock immediately.
    Process.send(self(), :try_acquire_lock, [])
    {:ok, %{is_leader: false, monitor_pid: nil}}
  end

  @impl true
  def handle_info(:try_acquire_lock, state) do
    case acquire_lock() do
      :ok ->
        Logger.info("Node became the HealthCheck leader.")
        new_state = if state.monitor_pid, do: state, else: start_monitor(state)
        Process.send_after(self(), :try_acquire_lock, @check_interval_ms)
        {:noreply, %{new_state | is_leader: true}}

      :error ->
        new_state = stop_monitor(state)
        Process.send_after(self(), :try_acquire_lock, @check_interval_ms)
        {:noreply, %{new_state | is_leader: false}}
    end
  end


  defp acquire_lock() do
    node_id = to_string(node())
    opts = [redis: ["NX", "PX", Integer.to_string(@lock_ttl_ms)]]

    case Cache.set(@lock_key, node_id, opts) do
      {:ok, :set} -> :ok
      _ -> :error
    end
  end

  defp start_monitor(state) do
    case RinhaVanilla.Health.Monitor.start_link(%{}) do
      {:ok, pid} -> %{state | monitor_pid: pid}
      _ -> state
    end
  end

  defp stop_monitor(%{monitor_pid: pid} = state) when is_pid(pid) do
    if Process.alive?(pid), do: Process.exit(pid, :normal)
    %{state | monitor_pid: nil}
  end

  defp stop_monitor(state), do: state
end
