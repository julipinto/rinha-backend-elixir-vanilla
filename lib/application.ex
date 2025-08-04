defmodule RinhaVanilla.Application do
  @moduledoc false
  use Application

  @impl true
  def start(_type, _args) do
    total_concurrency = Application.get_env(:rinha_vanilla, :total_concurrency, 500)

    children = [
      {Redix, name: RinhaVanilla.Redis},
      {Finch,
       name: RinhaVanilla.Finch, pools: %{:default => [size: total_concurrency, count: 1]}},
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
