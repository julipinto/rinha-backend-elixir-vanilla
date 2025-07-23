defmodule RinhaVanilla.Integrations.Processors.Transforms do
  alias RinhaVanilla.Integrations.Types.PaymentType

  def to_process_payment_body(%PaymentType{} = payment) do
    %{
      "correlationId" => payment.correlation_id,
      "amount" => payment.amount,
      "requestedAt" => payment.requested_at
    }
  end
end
