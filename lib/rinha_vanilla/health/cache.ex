defmodule RinhaVanilla.Health.Cache do
  @cache_key "gateway_health_status"

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
end
