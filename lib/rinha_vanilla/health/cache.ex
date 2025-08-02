defmodule RinhaVanilla.Health.HealthCache do
  @cache_key "gateway_health_status"
  @max_latency_overhead 1.25

  def get_status() do
    with {:ok, payload} <- Redix.command(RinhaVanilla.Redis, ["GET", @cache_key]),
         true <- not is_nil(payload),
         {:ok, status_map} <- Jason.decode(payload) do
      {:ok, status_map}
    else
      _ ->
        {:error, :not_available}
    end
  end

  def preferred_processor() do
    case get_status() do
      {:ok, %{"default" => ds, "fallback" => fs}} ->
        default_ok = Map.get(ds, "status") == "ok"
        fallback_ok = Map.get(fs, "status") == "ok"

        cond do
          default_ok and not fallback_ok ->
            :default

          not default_ok and fallback_ok ->
            :fallback

          default_ok and fallback_ok ->
            default_latency = ds["details"]["minResponseTime"]
            fallback_latency = fs["details"]["minResponseTime"]

            if default_latency > fallback_latency * @max_latency_overhead,
              do: :fallback,
              else: :default

          true ->
            :default
        end

      {:error, :not_available} ->
        :default
    end
  end

  def update_status(status_map) when is_map(status_map) do
    payload = Jason.encode!(status_map)
    RinhaVanilla.Cache.set(@cache_key, payload)
  end

  def report_failure(processor_atom) do
    with {:ok, current_status} <- get_status() do
      updated_status =
        Map.put(current_status, Atom.to_string(processor_atom), %{
          "status" => "failing",
          "details" => %{"error" => "Reported by worker in real-time"}
        })

      update_status(updated_status)
    else
      _error ->
        :ok
    end
  end
end
