defmodule RinhaVanillaWeb.Controllers.PaymentsController do
  import Plug.Conn

  require Logger

  alias RinhaVanilla.Validators.CreatePaymentValidator
  alias RinhaVanilla.Types.CreatePaymentType
  alias RinhaVanilla.Payments.CreatePayment
  alias RinhaVanilla.Validators.SummaryFiltersValidator
  alias RinhaVanilla.Types.SummaryFiltersType
  alias RinhaVanilla.Payments.PaymentsSummary
  alias RinhaVanilla.Payments.Purge

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
    query_params = conn |> fetch_query_params() |> Map.get(:query_params, %{})
    with {:ok, validated_params} <- SummaryFiltersValidator.validate(query_params),
         filters_struct = SummaryFiltersType.new(validated_params),
         summary_response = PaymentsSummary.generate_summary(filters_struct) do
      conn
      |> put_resp_content_type("application/json")
      |> send_resp(200, Jason.encode!(summary_response))
    else
      {:error, {:validation, reason}} ->
        Logger.error("Summary validation error: #{inspect(reason)}")
        send_resp(conn, 422, "Unprocessable Entity: #{reason}")

      _error ->
        send_resp(conn, 500, "Internal Server Error")
    end
  end

  def purge(conn) do
    case Purge.purge_all_data() do
      {:ok, _} ->
        send_resp(conn, 204, "")

      {:error, reason} ->
        Logger.error("Failed to purge data: #{inspect(reason)}")
        send_resp(conn, 500, "Failed to purge data")
    end
  end
end
