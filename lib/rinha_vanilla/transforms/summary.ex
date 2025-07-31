defmodule RinhaVanilla.Transforms.SummaryTransform do
  alias RinhaVanilla.Transforms.AmountTransform

  def to_response_format(summary_data) do
    Enum.into(summary_data, %{}, fn {processor, data} ->
      {
        Atom.to_string(processor), %{
          "totalRequests" => data.total_requests, #
          "totalAmount" => AmountTransform.from_cents(data.total_amount_in_cents) #
        }
      }
    end)
  end
end