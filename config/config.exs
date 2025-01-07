import Config

config :task_manager, ecto_repos: [TaskManager.Repo]

config :task_manager, TaskManager.Repo,
  adapter: Ecto.Adapters.SQLite3,
  database: "./database.db",
  pool_size: 10

config :task_manager, :pow,
  user: TaskManager.Users.User,
  repo: TaskManager.Repo

config :task_manager, Oban,
  engine: Oban.Engines.Lite,
  repo: TaskManager.Repo,
  queues: [default: 10]
