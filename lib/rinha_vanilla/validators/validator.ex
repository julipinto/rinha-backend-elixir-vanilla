defmodule RinhaVanilla.Validators.Validator do
  def validate_uuid(params, key) do
    uuid = Map.get(params, key)

    if is_binary(uuid) do
      validate_uuid_format(key, uuid)
    else
      {:error, "UUID must be a binary string in the field #{key}."}
    end
  end

  def validate_float_amount(params, key) do
    case Map.get(params, key) do
      amount when is_float(amount) and amount >= 0 -> {:ok, amount}
      _ -> {:error, "Amount must be a float in the field #{key}."}
    end
  end

  defp validate_uuid_format(
         key,
         <<a1::binary-size(8), "-", a2::binary-size(4), "-", a3::binary-size(4), "-",
           a4::binary-size(4), "-", a5::binary-size(12)>> = uuid
       ) do
    if valid_uuid_chars?(a1 <> a2 <> a3 <> a4 <> a5) do
      {:ok, uuid}
    else
      {:error, "Invalid UUID format on #{key}"}
    end
  end

  defp validate_uuid_format(key, _),
    do: {:error, "Invalid UUID format on #{key}"}

  defp valid_uuid_chars?(uuid) do
    String.match?(uuid, ~r/\A[0-9a-f]+\z/)
  end
end
