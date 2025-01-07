defmodule TaskManager.Router do
  @moduledoc """
  A Plug router for handling HTTP requests in the TaskManager application.

  This router manages routes for tasks, groups, and task-group associations,
  including CRUD operations and rendering HTML templates.
  """

  use Plug.Router

  alias TaskManager.{Template, Tasks, Groups, TasksGroups}
  alias Plug.Conn

  plug Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Jason
  plug Plug.MethodOverride
  plug Plug.Static, at: "/", from: :task_manager
  plug :match
  plug :dispatch

 @doc """
 Renders an HTML response using a template and assigns.

 This function takes a connection (`conn`), a template name, and a keyword list of assigns.
 It renders the template, sets the response content type to `text/html`, and sends the response
 with a 200 status code.

 ## Parameters

 - `conn`: The Plug connection.
 - `template`: The name of the template to render.
 - `assigns`: A keyword list of variables to pass to the template.

 ## Returns

 - A modified `conn` with the rendered HTML response.

 ## Examples

     # Render the "index" template with custom assigns
     render_html(conn, "index", title: "Home", user: %{name: "John"})
 """
 defp render_html(conn, template, assigns) do
   html = Template.render(template, assigns)
   conn
   |> Conn.put_resp_content_type("text/html")
   |> Conn.send_resp(200, html)
 end

 @doc """
 Handles errors from an Ecto changeset and sends a 400 response with error messages.

 This function takes a connection (`conn`) and an Ecto changeset. It extracts error messages
 from the changeset, formats them into a human-readable string, and sends a 400 response
 with the error messages.

 ## Parameters

 - `conn`: The Plug connection.
 - `changeset`: The Ecto changeset containing validation errors.

 ## Returns

 - A modified `conn` with a 400 response containing the error messages.

 ## Examples

     # Handle changeset errors
     changeset = User.changeset(%User{}, %{email: "invalid"})
     handle_changeset_error(conn, changeset)
 """
 defp handle_changeset_error(conn, changeset) do
   errors =
     changeset
     |> Ecto.Changeset.traverse_errors(fn {msg, opts} ->
       Enum.reduce(opts, msg, fn {key, value}, acc ->
         String.replace(acc, "%{#{key}}", to_string(value))
       end)
     end)
     |> Enum.map_join(", ", fn {field, message} -> "#{field}: #{message}" end)

   Conn.send_resp(conn, 400, "Ошибка: #{errors}")
 end

 @doc """
 Redirects the client to a specified path.

 This function takes a connection (`conn`) and a path. It sets the `location` header to the
 specified path and sends a 302 (Found) response with an empty body.

 ## Parameters

 - `conn`: The Plug connection.
 - `path`: The path to redirect to.

 ## Returns

 - A modified `conn` with a 302 redirect response.

 ## Examples

     # Redirect to the home page
     redirect(conn, "/")

     # Redirect to a specific resource
     redirect(conn, "/users/123")
 """
 defp redirect(conn, path) do
   conn
   |> Conn.put_resp_header("location", path)
   |> Conn.resp(302, "")
 end

  get "/" do
    tasks = Tasks.get_tasks()
    tasks_chart = Enum.reduce(tasks, %{"completed" => 0, "pending" => 0}, fn task, acc ->
      Map.update(acc, task.status, 1, &(&1 + 1))
    end)

    render_html(conn, "home", title: "Главная", tasks: tasks, tasks_chart: tasks_chart)
  end

  get "/tasks" do
    tasks = Tasks.get_tasks()
    render_html(conn, "tasks", title: "Задачи", tasks: tasks)
  end

  get "/tasks/all/:status" do
    tasks = Tasks.get_tasks_by_status(conn.params["status"])
    render_html(conn, "all_tasks", title: "Все задачи", tasks: tasks)
  end

  get "/tasks/find" do
    tasks = Tasks.get_tasks(conn.params)
    render_html(conn, "tasks_find", title: "Поиск задачи", tasks: tasks)
  end

  get "/tasks/task/:id" do
    task = Tasks.get_task(conn.params["id"])
    render_html(conn, "show_task", title: "Задача #{task.title}", task: task)
  end

  get "/tasks/new" do
    render_html(conn, "form_task", title: "Создание задачи", task: %Tasks{}, action: "/tasks/new", back: "/tasks")
  end

  post "/tasks/new" do
    task_params = %{
      title: conn.params["title"],
      desc: conn.params["desc"],
      status: conn.params["status"],
      priority: parse_priority(conn.params["priority"]),
      deadline: parse_datetime(conn.params["deadline"])
    }

    case Tasks.create_task(task_params) do
      {:ok, _task} -> redirect(conn, "/tasks")
      {:error, changeset} -> handle_changeset_error(conn, changeset)
    end
  end

  get "/tasks/edit/:id" do
    task = Tasks.get_task(conn.params["id"])
    render_html(conn, "form_task", title: "Редактирование задачи", task: task, action: "/tasks/edit/#{task.id}", back: "/tasks/task/#{task.id}")
  end

  get "/tasks/completed/:id" do
    case Tasks.completed_task(conn.params["id"]) do
      {:ok, _task} -> redirect(conn, "/tasks")
      {:error, :not_found} -> Conn.send_resp(conn, 404, "Группа не найдена")
      {:error, changeset} -> handle_changeset_error(conn, changeset)
    end
  end

  post "/tasks/edit/:id" do
    case Tasks.update_task(conn.params["id"], conn.params) do
      {:ok, _task} -> redirect(conn, "/tasks/task/#{conn.params["id"]}")
      {:error, changeset} -> handle_changeset_error(conn, changeset)
    end
  end

  get "/tasks/delete/:id" do
    case Tasks.delete_task(conn.params["id"]) do
      {:ok, _task} -> redirect(conn, "/tasks")
      {:error, :not_found} -> Conn.send_resp(conn, 404, "Задача не найдена")
      {:error, changeset} -> handle_changeset_error(conn, changeset)
    end
  end

  get "/groups" do
    groups = Groups.get_groups()
    render_html(conn, "groups", title: "Группы", groups: groups)
  end

  get "/groups/group/:group_id" do
    group = Groups.get_group(conn.params["group_id"])
    render_html(conn, "show_group", title: "Группа #{group.name}", group: group)
  end

  get "/groups/new" do
    render_html(conn, "form_group", title: "Создание группы", group: %Groups{}, action: "/groups/new", back: "/groups")
  end

  post "/groups/new" do
    group_params = %{
      name: conn.params["name"],
      desc: conn.params["desc"],
      is_pinned: parse_boolean(conn.params["is_pinned"]),
      image: conn.params["image"],
      deadline: parse_datetime(conn.params["deadline"])
    }

    case Groups.create_group(group_params) do
      {:ok, _group} -> redirect(conn, "/groups")
      {:error, changeset} -> handle_changeset_error(conn, changeset)
    end
  end

  get "/groups/edit/:id" do
    group = Groups.get_group(conn.params["id"])
    render_html(conn, "form_group", title: "Редактирование группы", group: group, action: "/groups/edit/#{group.id}", back: "/groups/group/#{group.id}")
  end

  get "/groups/pinned/:id" do
    case Groups.pinned_group(conn.params["id"]) do
      {:ok, _group} -> redirect(conn, "/groups/group/#{conn.params["id"]}")
      {:error, :not_found} -> Conn.send_resp(conn, 404, "Группа не найдена")
      {:error, changeset} -> handle_changeset_error(conn, changeset)
    end
  end

  post "/groups/edit/:id" do
    params = Map.put(conn.params, "is_pinned", parse_boolean(conn.params["is_pinned"]))

    case Groups.update_group(conn.params["id"], params) do
      {:ok, _group} -> redirect(conn, "/groups/group/#{conn.params["id"]}")
      {:error, changeset} -> handle_changeset_error(conn, changeset)
    end
  end

  get "/groups/delete/:id" do
    case Groups.delete_group(conn.params["id"]) do
      {:ok, _group} -> redirect(conn, "/groups")
      {:error, :not_found} -> Conn.send_resp(conn, 404, "Группа не найдена")
      {:error, changeset} -> handle_changeset_error(conn, changeset)
    end
  end

  get "/groups/add_tasks/:group_id" do
    group = Groups.get_group(conn.params["group_id"])
    tasks = TasksGroups.get_tasks_with_status(group.id)
    render_html(conn, "form_task_group", title: "Добавление задач в группу", group: group, tasks: tasks, action: "/groups/task/#{group.id}/add_task", back: "/groups/group/#{group.id}")
  end

  post "/groups/add_tasks/:group_id" do
    task_ids =
      conn.params["tasks_ids"]
      |> List.wrap()
      |> Enum.filter(&is_binary/1)
      |> Enum.map(&String.to_integer/1)

    case TasksGroups.add_tasks_to_group(String.to_integer(conn.params["group_id"]), task_ids) do
      {:ok, _group} -> redirect(conn, "/groups/group/#{conn.params["group_id"]}")
      {:error, _reason} -> Conn.send_resp(conn, 400, "Ошибка при добавлении задач")
    end
  end

  match _ do
    Conn.send_resp(conn, 404, "Not Found")
  end

  defp parse_priority(nil), do: 1
  defp parse_priority(priority_str), do: String.to_integer(priority_str)

  defp parse_boolean("on"), do: true
  defp parse_boolean(_), do: false

  defp parse_datetime(nil), do: nil
  defp parse_datetime(datetime_str) do
    case NaiveDateTime.from_iso8601(datetime_str <> ":00") do
      {:ok, datetime} -> datetime
      _ -> nil
    end
  end
end
