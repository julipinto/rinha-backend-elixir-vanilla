defmodule RinhaVanilla.Payments.PaymentsSummary do
  alias RinhaVanilla.PriorityQueueCache
  alias RinhaVanilla.Web.Parsers.SummaryParser
  alias RinhaVanilla.Types.SummaryFiltersType

  @processors [:default, :fallback]

  def generate_summary(%SummaryFiltersType{} = filters) do
    {start_time, end_time} = parse_time_filters(filters)

    summary_data =
      Enum.reduce(@processors, %{}, fn processor, acc ->
        processed_data = fetch_and_aggregate(processor, start_time, end_time)
        Map.put(acc, processor, processed_data)
      end)

    SummaryParser.to_response_format(summary_data)
  end

  defp parse_time_filters(%SummaryFiltersType{from: from, to: to}) do
    from_unix = to_unix_timestamp(from, "-inf")
    to_unix = to_unix_timestamp(to, "+inf")
    {from_unix, to_unix}
  end

  defp fetch_and_aggregate(processor, start_time, end_time) do
    key = "processed_payments:#{processor}"
    {:ok, results} = PriorityQueueCache.zrange_by_score(key, start_time, end_time)

    Enum.reduce(results, %{total_requests: 0, total_amount_in_cents: 0}, fn payload, acc ->
      {:ok, payment_data} = Jason.decode(payload)

      %{
        total_requests: acc.total_requests + 1,
        total_amount_in_cents: acc.total_amount_in_cents + payment_data["amount_in_cents"]
      }
    end)
  end

  defp to_unix_timestamp(nil, default), do: default

  defp to_unix_timestamp(iso_string, _default) do
    {:ok, datetime, _} = DateTime.from_iso8601(iso_string)
    DateTime.to_unix(datetime)
  end
end
