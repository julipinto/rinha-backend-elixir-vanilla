defmodule RinhaVanillaWeb.Controllers.PaymentsController do
  import Plug.Conn

  require Logger

  alias RinhaVanilla.Validators.CreatePaymentValidator
  alias RinhaVanilla.Types.CreatePaymentType
  alias RinhaVanilla.Payments.CreatePayment

  def handle_payment(conn) do
    with {:ok, body, _conn} <- Plug.Conn.read_body(conn),
         {:ok, params} <- Jason.decode(body),
         {:ok, validated_params} <- CreatePaymentValidator.validate(params),
         attrs = CreatePaymentType.new(validated_params),
         {:ok, _} <- CreatePayment.enqueue(attrs) do
      send_resp(conn, 201, "Accepted")
    else
      {:error, :invalid_json} ->
        send_resp(conn, 400, "Bad Request: Invalid JSON")

      {:error, {:validation, reason}} ->
        Logger.error("Validation error: #{inspect(reason)}")
        send_resp(conn, 422, "Unprocessable Entity: #{reason}")

      {:error, reason} ->
        Logger.error("Error processing payment: #{inspect(reason)}")
        send_resp(conn, 500, "Internal Server Error")

      _error ->
        send_resp(conn, 500, "Internal Server Error")
    end
  end

  def summary(conn) do
    # Logic to return payment summary
    send_resp(conn, 200, "Payment summary")
  end
end
