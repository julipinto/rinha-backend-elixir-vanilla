defmodule RinhaVanilla.Integrations.Types.PaymentType do
  @moduledoc """
  Module for defining payment types in the Rinha Vanilla application.
  """

  alias RinhaVanilla.Transforms.AmountTransform

  defstruct [:processor, :amount, :correlation_id, :requested_at]

  @doc """
  Transforms the payment amount to the required format.
  """
  def transform_amount(processor, %{
        amount_in_cents: amount,
        correlation_id: correlation_id,
        requested_at: requested_at
      }) do
    %__MODULE__{
      processor: processor,
      amount: AmountTransform.from_cents(amount),
      correlation_id: correlation_id,
      requested_at: requested_at
    }
  end

  def transform_amount(processor, %{
    "amount_in_cents" => amount,
    "correlation_id" => correlation_id,
    "requested_at" => requested_at
  }) do
    %__MODULE__{
      processor: processor,
      amount: AmountTransform.from_cents(amount),
      correlation_id: correlation_id,
      requested_at: requested_at
    }
  end
end
