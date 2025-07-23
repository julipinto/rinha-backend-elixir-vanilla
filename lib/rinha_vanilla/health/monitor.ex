defmodule RinhaVanilla.Health.Monitor do
  use GenServer

  require Logger

  alias RinhaVanilla.Integrations.ProcessorIntegrations
  alias RinhaVanilla.Cache

  # 5 segundos
  @check_interval_ms 5_000
  @cache_key "gateway_health_status"

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    Logger.info("HealthMonitor started. Running first check.")
    # Executes a first health check immediately.
    Process.send(self(), :run_health_check, [])
    {:ok, %{}}
  end

  @impl true
  def handle_info(:run_health_check, state) do
    # Verificamos a saúde de ambos os processadores em paralelo.
    tasks = [
      Task.async(fn -> {:default, ProcessorIntegrations.health_check(:default)} end),
      Task.async(fn -> {:fallback, ProcessorIntegrations.health_check(:fallback)} end)
    ]

    results = Task.await_many(tasks, 5000)
    # Processamos os resultados e salvamos no cache.
    save_status_to_cache(results)

    # Agendamos o próximo check.
    Process.send_after(self(), :run_health_check, @check_interval_ms)
    {:noreply, state}
  end

  # --- Funções Privadas ---

  defp save_status_to_cache(results) do
    status_map =
      Enum.into(results, %{}, fn
        {processor, {:ok, body}} ->
          case Jason.decode(body) do
            {:ok, decoded_body} ->
              {processor, %{status: :ok, details: decoded_body}}

            _ ->
              {processor, %{status: :error, details: %{}}}
          end

        {processor, {:error, _reason}} ->
          # Timeout ou qualquer erro: indisponível
          {processor, %{status: :error, details: %{}}}
      end)

    {:ok, payload} = Jason.encode(status_map)
    Cache.set(@cache_key, payload)
    Logger.info("Health status cache updated.")
    {:ok, :set}
  end
end
