defmodule RinhaVanilla.Integrations.Processor.Config do
  @moduledoc false

  def add_admin_token do
    {"X-Rinha-Token", "123"}
  end

  def health_check_route(processor) do
    url = get_processor_url(processor)
    "#{url}/payments/service-health"
  end

  def payment_route(processor) do
    url = get_processor_url(processor)
    "#{url}/payments"
  end

  def purge_route(processor) do
    url = get_processor_url(processor)
    "#{url}/admin/purge-payments"
  end

  def client(_processor) do
    RinhaVanilla.Finch
  end

  def get_processor_url(:default) do
    Application.get_env(:rinha_2025, :processor_url, "http://localhost:8001")
  end

  def get_processor_url(:fallback) do
    Application.get_env(:rinha_2025, :fallback_processor_url, "http://localhost:8002")
  end
end
