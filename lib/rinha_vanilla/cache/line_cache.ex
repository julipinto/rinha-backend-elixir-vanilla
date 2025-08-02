defmodule RinhaVanilla.Cache.RegularQueueCache do
  @moduledoc """
  A module for managing Redis Line Cache operations.
  """
  require Logger

  import RinhaVanilla.Cache, only: [namespaced_key: 1, command: 1]

  def ladd(key, payload) do
    key = namespaced_key(key)

    case command(["LPUSH", key, payload]) do
      {:ok, 1} -> {:ok, :added}
      {:ok, 0} -> {:ok, :already_exists}
      {:error, reason} -> {:error, reason}
    end
  end

  def rpop(key, count) do
    key = namespaced_key(key)

    case command(["RPOP", key, count]) do
      {:ok, results} when is_list(results) ->
        results

      # Fila vazia
      {:ok, nil} ->
        []

      {:error, reason} ->
        Logger.error("Error fetching from Redis with RPOP: #{inspect(reason)}")
        []
    end
  end
end
