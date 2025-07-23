defmodule RinhaVanilla.Types.CreatePaymentType do
  @moduledoc """
  Defines the structure for creating a payment.
  """
  import RinhaVanilla.Transforms.AmountTransform, only: [to_cents: 1]

  defstruct [:correlation_id, :amount_in_cents, :requested_at]

  def new(params) do
    %__MODULE__{
      correlation_id: Map.get(params, "correlationId"),
      amount_in_cents: params |> Map.get("amount") |> to_cents(),
      requested_at: DateTime.utc_now() |> DateTime.to_iso8601()
    }
  end
end
