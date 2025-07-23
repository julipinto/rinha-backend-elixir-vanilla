defmodule RinhaVanilla.Cache do
  @moduledoc """
  A module for managing cache operations.
  """

  @namespace "{rinha}"

  def get(key, opts \\ []) do
    key = namespaced_key(key)

    case Redix.command(RinhaVanilla.Redis, ["GET", key]) do
      {:ok, nil} -> {:error, :not_found}
      {:ok, value} -> {:ok, parse_output(value, json: Keyword.get(opts, :json, false))}
      {:error, reason} -> {:error, reason}
    end
  end

  def set(key, value, opts \\ []) do
    key = namespaced_key(key)
    value = parse_input(value, json: Keyword.get(opts, :json, false))
    redis_opts = Keyword.get(opts, :redis, [])

    case Redix.command(RinhaVanilla.Redis, ["SET", key, value] ++ redis_opts) do
      {:ok, "OK"} -> {:ok, :set}
      {:error, reason} -> {:error, reason}
      other -> other
    end
  end

  def namespaced_key(key) when is_binary(key) do
    "#{@namespace}:#{key}"
  end

  def namespaced_key(key) when is_atom(key) do
    "#{@namespace}:#{Atom.to_string(key)}"
  end

  defp parse_output(value, json: false), do: value

  defp parse_output(value, json: true) do
    case Jason.decode(value) do
      {:ok, decoded} -> decoded
      {:error, _} -> value
    end
  end

  defp parse_input(input, json: false), do: input

  defp parse_input(input, json: true) do
    case Jason.encode(input) do
      {:ok, encoded} -> encoded
      {:error, _} -> input
    end
  end

  # Wrapper para comandos diretos no Redis, para uso interno
  @doc false
  def command(args) do
    Redix.command(RinhaVanilla.Redis, args)
  end
end
