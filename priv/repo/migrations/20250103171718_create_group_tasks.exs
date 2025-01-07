defmodule TaskManager.Repo.Migrations.CreateGroupTasks do
  use Ecto.Migration

  def up do
    create table(:groups, primary_key: true) do
      add :name, :string, null: false
      add :desc, :text
      add :is_pinned, :boolean, default: false
      add :deadline, :naive_datetime, null: true
      add :image, :text, null: true
      timestamps()
    end


    create table(:task_groups) do
    add :task_id, references(:tasks, on_delete: :delete_all)
    add :group_id, references(:groups, on_delete: :delete_all)

    timestamps()
    end

    create unique_index(:task_groups, [:task_id, :group_id], name: :task_groups_task_id_group_id_index)
  end

def down do
drop table(:groups)
drop index(:task_groups, [:task_id, :group_id])
drop table(:task_groups)
end
end
