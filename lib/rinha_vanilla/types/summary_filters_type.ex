defmodule RinhaVanilla.Types.SummaryFiltersType do
  @moduledoc """
  Represents the validated filters for the payments summary endpoint.
  """
  defstruct [:from, :to]

  @doc """
  Creates a new SummaryFiltersType struct from a map of validated parameters.
  """
  def new(params) do
    %__MODULE__{
      from: Map.get(params, "from"),
      to: Map.get(params, "to")
    }
  end
end
