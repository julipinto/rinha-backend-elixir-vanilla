defmodule RinhaVanilla.Payments.SuccessTracker do
  alias RinhaVanilla.Cache

  @summary_key_prefix "processed_payments:"
  @stats_key "payments_processed_stats"

  def track(processor_atom, data) do
    requested_at_iso = data["requested_at"]
    {:ok, datetime, _} = DateTime.from_iso8601(requested_at_iso)
    timestamp_ms = DateTime.to_unix(datetime, :millisecond)

    summary_command = build_summary_command(processor_atom, data, timestamp_ms)
    stats_command = build_stats_command(data)
    all_commands = [summary_command, stats_command]

    Cache.pipeline(all_commands)
  end

  defp build_summary_command(processor_atom, data, timestamp_ms) do
    summary_key = "#{@summary_key_prefix}#{processor_atom}"

    summary_payload =
      Jason.encode!(%{
        correlation_id: data["correlation_id"],
        amount_in_cents: data["amount_in_cents"],
        requested_at: data["requested_at"],
      })

    [:zadd, summary_key, timestamp_ms, summary_payload]
  end

  defp build_stats_command(data) do
    amount_in_cents = data["amount_in_cents"]
    correlation_id = data["correlation_id"]
    [:zadd, @stats_key, amount_in_cents, correlation_id]
  end
end
