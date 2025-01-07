defmodule TaskManager.Tasks do
  @moduledoc """
  Provides functions for managing tasks in the database.

  This module handles CRUD operations for tasks, including validation and querying.
  """

  alias TaskManager.{Repo, TasksGroups}
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query

  schema "tasks" do
    field :title, :string
    field :desc, :string
    field :status, :string, default: "pending"
    field :priority, :integer, default: 1
    field :deadline, :naive_datetime
    field :completed_at, :naive_datetime

    has_many :tasks_groups, TasksGroups

    timestamps()
  end

  @doc """
  Validates and casts task attributes into a changeset.
  """
  def changeset(task, attrs) do
    task
    |> cast(attrs, [:title, :desc, :status, :priority, :deadline, :completed_at])
    |> validate_required([:title, :status])
    |> validate_inclusion(:status, ["pending", "in_progress", "completed"])
    |> validate_number(:priority, greater_than_or_equal_to: 1)
  end

  @doc """
  Fetches all tasks from the database.
  """
  def get_tasks, do: Repo.all(from(t in __MODULE__))

  @doc """
  Fetches all groups from the database with params
  """
  def get_tasks(params \\ %{}) do
    Repo.all(from(t in __MODULE__, where: like(t.title, ^"%#{params["search"]}%")))
  end

   @doc """
   Fetches all groups from the database with params
   """
   def get_tasks_by_status(status) do
    query =
      case status do
        "overtime" ->
          from(t in __MODULE__,
            where: not is_nil(t.deadline) and t.deadline < ^NaiveDateTime.utc_now()
          )
        "all" -> from(t in __MODULE__)
        _ ->
          from(t in __MODULE__, where: t.status == ^status)
      end

    Repo.all(query)
  end

  @doc """
  Fetches a single task by its ID.
  """
  def get_task(task_id), do: Repo.get(__MODULE__, task_id)

  @doc """
  Creates a new task with the given attributes.
  """
  def create_task(attrs \\ %{}) do
    %__MODULE__{}
    |> changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Marks a task as completed by setting `completed_at` to the current time.
  """
  def completed_task(task_id) do
    case get_task(task_id) do
      nil -> {:error, :not_found}
      task ->
        params = if task.status == "completed" do
          %{completed_at: nil, status: "in_progress"}
        else
          %{completed_at: NaiveDateTime.utc_now(), status: "completed"}
        end

        changeset = changeset(task, params)

        Repo.update(changeset)
    end
  end

  @doc """
  Checks if any tasks have missed their deadlines.
  """
  def has_missed_deadlines?(tasks) do
    tasks
      |> Enum.filter(fn task ->
        not is_nil(task.deadline) and NaiveDateTime.compare(task.deadline, NaiveDateTime.utc_now()) == :lt and task.status != "completed"
      end)
  end

  @doc """
  Updates an existing task with the given attributes.
  """
  def update_task(task_id, params) do
    case get_task(task_id) do
      nil -> {:error, :not_found}
      task -> task |> changeset(params) |> Repo.update()
    end
  end

  @doc """
  Deletes a task by its ID.
  """
  def delete_task(task_id) do
    case get_task(task_id) do
      nil -> {:error, :not_found}
      task -> Repo.delete(task)
    end
  end
end
