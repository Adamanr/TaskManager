defmodule TaskManager.Repo.Migrations.CreateTasks do
  use Ecto.Migration

  def up do
    create table(:tasks, primary_key: true) do
      add :title, :string, null: false
      add :desc, :text
      add :status, :string, null: false, default: "pending"
      add :priority, :integer, default: 1
      add :deadline, :naive_datetime
      add :completed_at, :naive_datetime

      timestamps()
    end

    create index(:tasks, [:status, :title])
  end

  def down do
    drop table(:tasks)
    drop index(:tasks, [:status, :title])
  end
end
