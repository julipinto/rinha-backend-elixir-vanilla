defmodule RinhaVanilla.Integrations.Types.PaymentType do
  @moduledoc """
  Module for defining payment types in the Rinha Vanilla application.
  """

  defstruct [:processor, :amount, :correlation_id, :requested_at]

  @doc """
  Transforms the payment amount to the required format.
  """
  def transform_amount(processor, %{
        amount: amount,
        correlation_id: correlation_id
        # requested_at: _requested_at
      }) do
    %__MODULE__{
      processor: processor,
      amount: amount,
      correlation_id: correlation_id,
      # requested_at: requested_at
      requested_at: DateTime.utc_now() |> DateTime.truncate(:millisecond) |> DateTime.to_iso8601()
    }
  end

  def transform_amount(processor, %{
        "amount" => amount,
        "correlation_id" => correlation_id,
        # "requested_at" => _requested_at
      }) do
    %__MODULE__{
      processor: processor,
      amount: amount,
      correlation_id: correlation_id,
      # requested_at: requested_at
      requested_at: DateTime.utc_now() |> DateTime.truncate(:millisecond) |> DateTime.to_iso8601()
    }
  end
end
