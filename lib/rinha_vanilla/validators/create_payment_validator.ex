defmodule RinhaVanilla.Validators.CreatePaymentValidator do
  alias RinhaVanilla.Validators.Validator
  require Logger

  def validate(params) do
    with {:ok, _uuid} <- Validator.validate_uuid(params, "correlationId"),
         {:ok, _validated_params} <- Validator.validate_float_amount(params, "amount") do
      {:ok, params}
    else
      {:error, reason} ->
        Logger.error("Validation error: #{inspect(reason)} for params: #{inspect(params)}")
        {:error, {:validation, reason}}
    end
  end
end
