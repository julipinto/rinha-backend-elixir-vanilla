defmodule RinhaVanilla.Payments.PaymentQueueRouter do
  require Logger

  alias RinhaVanilla.Stats.Tracker

  @high_value_queue :high_value_queue
  @standard_queue :payments_queue

  def route(payment_attrs) do
    case Tracker.get_high_value_threshold() do
      {:ok, threshold} when payment_attrs.amount_in_cents > threshold ->
        {:high_value, @high_value_queue}

      _ ->
        {:standard, @standard_queue}
    end
  end
end
