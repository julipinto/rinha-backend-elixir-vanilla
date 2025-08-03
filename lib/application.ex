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

    with {:ok, pid} <- Supervisor.start_link(children, opts) do
      # We are always cleaning up the cache on startup to minimize stale data, but in a real application,
      # you might want to conditionally clean up based on some criteria.
      RinhaVanilla.Cache.cleanup()
      {:ok, pid}
    end
  end
end
