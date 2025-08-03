defmodule RinhaVanilla.Web.Parsers.SummaryParser do
  def to_response_format(summary_data) do
    Enum.into(summary_data, %{}, fn {processor, data} ->
      {
        Atom.to_string(processor),
        %{
          "totalRequests" => data.total_requests,
          "totalAmount" => data.total_amount
        }
      }
    end)
  end
end
