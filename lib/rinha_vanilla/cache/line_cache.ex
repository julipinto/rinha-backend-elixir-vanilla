defmodule RinhaVanilla.Cache.LineCache do
  @moduledoc """
  A module for managing Redis Line Cache operations.
  """
  require Logger

  import RinhaVanilla.Cache, only: [namespaced_key: 1, command: 1]

  @max_bulk_size 1000

  def ladd(key, payload) do
    key = namespaced_key(key)

    case command(["LPUSH", key, payload]) do
      {:ok, 1} -> {:ok, :added}
      {:ok, 0} -> {:ok, :already_exists}
      {:error, reason} -> {:error, reason}
    end
  end
end
