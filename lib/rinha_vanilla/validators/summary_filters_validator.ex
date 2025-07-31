defmodule RinhaVanilla.Validators.SummaryFiltersValidator do
  @moduledoc """
  Validates the query parameters for the payments summary endpoint.
  """
  def validate(params) do
    with :ok <- validate_optional_timestamp(params, "from"),
         :ok <- validate_optional_timestamp(params, "to") do
      {:ok, params}
    else
      {:error, reason} -> {:error, {:validation, reason}}
    end
  end

  defp validate_optional_timestamp(params, key) do
    case Map.get(params, key) do
      nil ->
        :ok

      timestamp_str when is_binary(timestamp_str) ->
        case DateTime.from_iso8601(timestamp_str) do
          {:ok, _datetime, _offset} -> :ok
          {:error, _reason} -> {:error, "Invalid ISO 8601 format for key '#{key}'"}
        end

      _ ->
        {:error, "Filter '#{key}' must be a string."}
    end
  end
end
