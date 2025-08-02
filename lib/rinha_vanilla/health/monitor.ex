defmodule RinhaVanilla.Health.Monitor do
  use GenServer

  require Logger

  alias RinhaVanilla.Integrations.ProcessorIntegrations
  alias RinhaVanilla.Cache

  # 5 segundos
  @check_interval_ms 5_000

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    Logger.info("HealthMonitor started. Running first check.")
    Process.send(self(), :run_health_check, [])
    {:ok, %{}}
  end

  @impl true
  def handle_info(:run_health_check, state) do
    tasks = [
      Task.async(fn -> {:default, ProcessorIntegrations.health_check(:default)} end),
      Task.async(fn -> {:fallback, ProcessorIntegrations.health_check(:fallback)} end)
    ]

    results = Task.await_many(tasks, 5000)

    status_map = build_status_map(results)
    Cache.update_status(status_map)

    Logger.info("Health status cache updated by monitor.")
    Process.send_after(self(), :run_health_check, @check_interval_ms)
    {:noreply, state}
  end

  defp build_status_map(results) do
    Enum.into(results, %{}, fn
      {processor, {:ok, body}} ->
        case Jason.decode(body) do
          {:ok, decoded_body} ->
            {Atom.to_string(processor), %{status: "ok", details: decoded_body}}

          _ ->
            {Atom.to_string(processor), %{status: "failing", details: %{}}}
        end

      {processor, {:error, _reason}} ->
        {Atom.to_string(processor), %{status: "failing", details: %{}}}
    end)
  end
end
