defmodule RinhaVanilla.Transforms.SummaryTransform do
  def to_response_format(summary_data) do
    Enum.into(summary_data, %{}, fn {processor, data} ->
      {
        Atom.to_string(processor),
        %{
          "totalRequests" => data.total_requests,
          "totalAmount" => data.amount
        }
      }
    end)
  end
end
