defmodule RinhaVanilla.Payments.PaymentQueueRouter do
  use GenServer
  require Logger

  alias RinhaVanilla.Stats.Tracker

  @high_value_queue :high_value_queue
  @standard_queue :payments_queue

  def route(payment_attrs) do
    case Tracker.get_high_value_threshold() do
      {:ok, threshold_str}
      when payment_attrs.amount_in_cents > String.to_integer(threshold_str) ->
        {:high_value, @high_value_queue}

      _ ->
        {:standard, @standard_queue}
    end
  end
end
