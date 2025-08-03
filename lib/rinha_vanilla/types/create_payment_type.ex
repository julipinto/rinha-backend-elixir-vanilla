defmodule RinhaVanilla.Types.CreatePaymentType do
  @moduledoc """
  Defines the structure for creating a payment.
  """
  defstruct [:correlation_id, :amount, :requested_at, :amount_in_cents]

  def new(params) do
    %__MODULE__{
      correlation_id: Map.get(params, "correlationId"),
      amount: params |> Map.get("amount"),
      amount_in_cents: params |> Map.get("amount") |> Kernel.*(100) |> trunc(),
      # requested_at: DateTime.utc_now() |> DateTime.to_iso8601()
    }
  end
end
