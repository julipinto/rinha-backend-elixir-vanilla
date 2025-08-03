defmodule RinhaVanilla.PriorityQueueCache do
  @moduledoc """
  A module for managing Redis Sorted Set operations.
  """
  require Logger

  import RinhaVanilla.Cache, only: [namespaced_key: 1, command: 1]

  @max_bulk_size 1000

  def zadd(key, payload, score) do
    key = namespaced_key(key)

    case command(["ZADD", key, score, payload]) do
      {:ok, 1} -> {:ok, :added}
      {:ok, 0} -> {:ok, :already_exists}
      {:error, reason} -> {:error, reason}
    end
  end

  def zrange_with_scores(key, start_index, end_index) do
    key = namespaced_key(key)
    command(["ZRANGE", key, start_index, end_index, "WITHSCORES"])
  end

  def bulk_zadd(key, score_payload_list) when is_list(score_payload_list) do
    key = namespaced_key(key)

    failures =
      score_payload_list
      |> Enum.chunk_every(@max_bulk_size)
      |> Enum.reduce([], fn chunk, acc ->
        command =
          ["ZADD", key] ++ Enum.flat_map(chunk, fn {score, payload} -> [score, payload] end)

        case command(command) do
          {:ok, _} ->
            acc

          {:error, reason} ->
            Logger.error("ZADD failed for chunk: #{inspect(chunk)}\nReason: #{inspect(reason)}")
            [{chunk, reason} | acc]
        end
      end)

    if failures == [] do
      {:ok, :all_succeeded}
    else
      {:error, Enum.reverse(failures)}
    end
  end

  def zpomax(key, demand) do
    key = namespaced_key(key)

    case command(["ZPOPMAX", key, demand]) do
      {:ok, results} when is_list(results) ->
        results
        |> Enum.chunk_every(2)
        |> Enum.map(fn [value, _score] -> value end)

      {:ok, nil} ->
        []

      {:error, reason} ->
        Logger.error("Error fetching from Redis: #{inspect(reason)}")
        []
    end
  end

  def zpopmin(key, demand) do
    key = namespaced_key(key)

    case command(["ZPOPMIN", key, demand]) do
      {:ok, results} when is_list(results) ->
        results
        |> Enum.chunk_every(2)
        |> Enum.map(fn [value, _score] -> value end)

      {:ok, nil} ->
        []

      {:error, reason} ->
        Logger.error("Error fetching from Redis with ZPOPMIN: #{inspect(reason)}")
        []
    end
  end

  def zrange_by_score(key, start_score, end_score) do
    key = namespaced_key(key)
    command(["ZRANGE", key, start_score, end_score, "BYSCORE"])
  end

  def zcard(key) do
    key = namespaced_key(key)
    command(["ZCARD", key])
  end
end
