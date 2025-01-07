defmodule TaskManager.TasksGroups do
  @moduledoc """
  Module for managing associations between tasks and groups.

  This module provides functions for working with task-group associations,
  including creating, deleting, and retrieving relationships, as well as
  checking task statuses within the context of a specific group.

  ## Examples

  ### Retrieve all task-group associations
  ```elixir
  TaskManager.TasksGroups.get_task_groups()
  ```
  """

  use Ecto.Repo,
    otp_app: :task_manager,
    adapter: Ecto.Adapters.SQLite3

  alias TaskManager.{Repo, Tasks, Groups}
  use Ecto.Schema
  import Ecto.{Changeset, Query}

  schema "task_groups" do
    belongs_to :task, Tasks, foreign_key: :task_id
    belongs_to :group, Groups, foreign_key: :group_id

    timestamps()
  end


  @doc """
  Creates a changeset for task-group associations.
  """
  def changeset(task_groups, params \\ %{}) do
    task_groups
    |> cast(params, [:task_id, :group_id])
    |> validate_required([:task_id, :group_id])
    |> unique_constraint([:task_id, :group_id], name: :task_groups_task_id_group_id_index)
  end

  @doc """
  Retrieves all task-group associations from the database.
  """
  def get_task_groups do
    __MODULE__
    |> Repo.all()
  end

  @doc """
  Retrieves tasks with their association status for a specific group.

  Each task is annotated with an :is_added field indicating whether it is
  associated with the given group.
  """
  def get_tasks_with_status(group_id) do
    existing_task_ids =
      __MODULE__
      |> where([tg], tg.group_id == ^group_id)
      |> select([tg], tg.task_id)
      |> Repo.all()
      |> MapSet.new()

    Tasks.get_tasks()
    |> Enum.map(&Map.put(&1, :is_added, MapSet.member?(existing_task_ids, &1.id)))
  end

  @doc """
  Adds or removes tasks from a group based on the provided task IDs.

  If the group does not exist, returns an error.
  """
  def add_tasks_to_group(group_id, task_ids) do
    case Repo.get(Groups, group_id) do
      nil -> {:error, "Группа с ID #{group_id} не найдена"}
      _group -> update_group_tasks(group_id, task_ids)
    end
  end

  defp update_group_tasks(group_id, task_ids) do
    Repo.transaction(fn ->
      existing_task_ids = get_existing_task_ids(group_id)
      new_task_ids = MapSet.new(task_ids)

      tasks_to_add = MapSet.difference(new_task_ids, existing_task_ids)
      tasks_to_remove = MapSet.difference(existing_task_ids, new_task_ids)

      Enum.each(tasks_to_add, &insert_task_group(group_id, &1))
      Enum.each(tasks_to_remove, &delete_task_group(group_id, &1))

      :ok
    end)
  end

  defp get_existing_task_ids(group_id) do
    __MODULE__
    |> where([tg], tg.group_id == ^group_id)
    |> select([tg], tg.task_id)
    |> Repo.all()
    |> MapSet.new()
  end

  defp insert_task_group(group_id, task_id) do
    %__MODULE__{}
    |> changeset(%{group_id: group_id, task_id: task_id})
    |> Repo.insert!()
  end

  defp delete_task_group(group_id, task_id) do
    __MODULE__
    |> where([tg], tg.group_id == ^group_id and tg.task_id == ^task_id)
    |> Repo.delete_all()
  end
end
