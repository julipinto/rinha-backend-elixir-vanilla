defmodule RinhaVanilla.Integrations.ProcessorIntegrations do
  @moduledoc """
  Module for handling processor integrations in the Rinha Vanilla application.
  """

  alias RinhaVanilla.Integrations.Processor.HttpProcessor
  alias RinhaVanilla.Integrations.Types.PaymentType
  alias RinhaVanilla.Integrations.Processors.Transforms

  def health_check(processor) do
    HttpProcessor.health_check(processor)
  end

  def process_payment(%PaymentType{} = payload) do
    processor = payload.processor
    body = Transforms.to_process_payment_body(payload)
    HttpProcessor.process_payment(processor, body)
  end

  def purge(processor) do
    HttpProcessor.purge(processor)
  end
end
