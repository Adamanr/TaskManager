defmodule TaskManager.Groups do
  @moduledoc """
  Provides functions for managing groups in the TaskManager application.

  This module handles CRUD operations for groups, including validation and querying.
  """

  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query
  alias TaskManager.{Repo, TasksGroups}

  schema "groups" do
    field :name, :string
    field :is_pinned, :boolean, default: false
    field :deadline, :naive_datetime
    field :desc, :string
    field :image, :string

    has_many :task_groups, TasksGroups
    has_many :tasks, through: [:task_groups, :task]

    timestamps()
  end

  @doc """
  Validates and casts group attributes into a changeset.
  """
  def changeset(group, attrs \\ %{}) do
    group
    |> cast(attrs, [:name, :is_pinned, :deadline, :image, :desc])
    |> validate_required([:name])
    |> validate_length(:name, min: 1, max: 100)
    |> validate_length(:image, max: 500)
  end

  @doc """
  Fetches all groups from the database.
  """
  def get_groups, do: Repo.all(from(g in __MODULE__))

  @doc """
  Fetches a single group by its ID, including associated tasks.
  """
  def get_group(group_id, tasks_nil \\ false) do
    case tasks_nil do
      true -> Repo.get(__MODULE__, group_id)
      false -> case Repo.get(__MODULE__, group_id) do
        nil -> nil
        group ->
          tasks =
            from(t in TaskManager.Tasks,
              join: tg in TasksGroups,
              on: tg.task_id == t.id,
              where: tg.group_id == ^group_id,
              select: t
            )
            |> Repo.all()

          Map.put(group, :tasks, tasks)
      end
    end
  end

  @doc """
  Pinned a group in groups lists
  """
  def pinned_group(group_id) do
    case get_group(group_id, true) do
      nil -> {:error, :not_found}
      group ->
        params = if group.is_pinned == true do
          %{is_pinned: false}
        else
          %{is_pinned: true}
        end

        changeset = changeset(group, params)

        Repo.update(changeset)
    end
  end

  @doc """
  Creates a new group with the given attributes.
  """
  def create_group(attrs \\ %{}) do
    %__MODULE__{}
    |> changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates an existing group with the given attributes.
  """
  def update_group(group_id, params) do
    case Repo.get(__MODULE__, group_id) do
      nil -> {:error, :not_found}
      group -> group |> changeset(params) |> Repo.update()
    end
  end

  @doc """
  Deletes a group by its ID.
  """
  def delete_group(group_id) do
    case Repo.get(__MODULE__, group_id) do
      nil -> {:error, :not_found}
      group -> Repo.delete(group)
    end
  end
end
