defmodule RinhaVanilla.Application do
  @moduledoc false
  use Application

  @impl true
  def start(_type, _args) do
    children = [
      {Redix, name: RinhaVanilla.Redis},
      {Finch, name: RinhaVanilla.Finch},
      RinhaVanilla.Health.LeaderElector,
      RinhaVanilla.Payments.StandardPayment.Pipeline,
      RinhaVanilla.Stats.ThresholdManager,
      RinhaVanilla.Pipelines.HighPayment.Pipeline,
      {Bandit, plug: RinhaVanilla.Plug.Router, port: 9999}
    ]

    opts = [strategy: :one_for_one, name: RinhaVanilla.Supervisor]

    Supervisor.start_link(children, opts)
  end
end
