defmodule TaskManager.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      TaskManager.Repo,
      {Bandit, plug: TaskManager.Router, scheme: :http, port: 4000},
    ]

    opts = [strategy: :one_for_one, name: TaskManager.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
