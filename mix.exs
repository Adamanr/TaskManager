defmodule TaskManager.MixProject do
  use Mix.Project

  def project do
    [
      app: :task_manager,
      version: "0.1.0",
      elixir: "~> 1.17",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {TaskManager.Application, []}
    ]
  end

  defp deps do
    [
      {:ecto_sql, "~> 3.12"},
      {:ecto_sqlite3, "~> 0.18.0"},
      {:bandit, "~> 1.6.2"},
      {:ex_doc, "~> 0.30", only: :dev, runtime: false},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:exsync, "~> 0.4.1", only: :dev}
    ]
  end
end
