defmodule RinhaVanilla.Integrations.Processor.HttpProcessor do
  @moduledoc """
  HTTP Processor for handling payment requests in the Rinha 2025 application using Finch.
  """
  require Logger
  alias RinhaVanilla.Integrations.Processor.Config

  def health_check(processor) do
    url = Config.health_check_route(processor)
    client = Config.client(processor)

    request = Finch.build(:get, url)

    case Finch.request(request, client) do
      {:ok, %Finch.Response{status: 200, body: body}} ->
        {:ok, body}

      {:ok, %Finch.Response{status: status}} ->
        Logger.error("Health check failed with status #{status} for processor #{processor}")
        {:error, "Health check failed with status #{status}"}

      {:error, reason} ->
        Logger.error("Health check failed for processor #{processor}: #{inspect(reason)}")
        {:error, "Health check failed for processor #{processor}: #{inspect(reason)}"}
    end
  end

  def process_payment(processor, payment_payload) do
    url = Config.payment_route(processor)
    client = Config.client(processor)

    headers = [{"content-type", "application/json"}]
    body = Jason.encode!(payment_payload)

    request = Finch.build(:post, url, headers, body)

    case Finch.request(request, client) do
      {:ok, %Finch.Response{status: 200, body: body}} ->
        {:ok, Jason.decode!(body)}

      {:ok, %Finch.Response{status: status, body: body}} ->
        Logger.warning("Payment processing returned status #{status} for processor #{processor} with body: #{body}")
        {:error, "Payment processing failed with status #{status} for processor #{processor}"}

      {:error, reason} ->
        Logger.error("Payment processing failed for processor #{processor}: #{inspect(reason)}")
        {:error, "Payment processing failed for processor #{processor}: #{inspect(reason)}"}
    end
  end

  def purge(processor) do
    url = Config.purge_route(processor)
    client = Config.client(processor)

    request = Finch.build(:post, url, [Config.add_admin_token()])

    case Finch.request(request, client) do
      {:ok, %Finch.Response{status: 200}} ->
        {:ok, :purged}

      {:ok, %Finch.Response{status: status, body: body}} ->
        Logger.error("Purge failed with status #{status} and body: #{body}")
        {:error, "Purge failed with status #{status}"}

      {:error, reason} ->
        Logger.error("Purge failed: #{inspect(reason)}")
        {:error, "Purge failed: #{inspect(reason)}"}
    end
  end
end
