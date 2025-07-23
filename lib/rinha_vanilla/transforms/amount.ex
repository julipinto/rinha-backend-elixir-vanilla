defmodule RinhaVanilla.Transforms.AmountTransform do
  def to_cents(amount) when is_number(amount) do
    trunc(amount * 100)
  end

  def from_cents(amount) when is_integer(amount) do
    amount / 100.0
  end
end
