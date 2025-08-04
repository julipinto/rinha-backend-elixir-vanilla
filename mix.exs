defmodule RinhaVanilla.MixProject do
  use Mix.Project

  def project do
    [
      app: :rinha_vanilla,
      version: "0.1.0",
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases(),
      releases: [
        rinha_vanilla: [
          include_executables_for: [:unix],
          applications: [runtime_tools: :permanent]
        ]
      ]
    ]
  end

  def application do
    [
      mod: {RinhaVanilla.Application, []},
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:bandit, "~> 1.0"},
      {:redix, "~> 1.5"},
      {:castore, "~> 1.0"},
      {:jason, "~> 1.4"},
      {:broadway, "~> 1.2"},
      {:finch, "~> 0.20"}
    ]
  end

  defp aliases do
    [
      setup: ["deps.get", "compile"],
      server: ["run --no-halt"]
    ]
  end
end
