defmodule RinhaVanilla.Types.CreatePaymentType do
  @moduledoc """
  Defines the structure for creating a payment.
  """
  defstruct [:correlation_id, :amount, :requested_at]

  def new(params) do
    %__MODULE__{
      correlation_id: Map.get(params, "correlationId"),
      amount: params |> Map.get("amount"),
      requested_at: DateTime.utc_now() |> DateTime.to_iso8601()
    }
  end
end
