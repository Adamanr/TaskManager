defmodule TaskManager.Template do
  @moduledoc """
    This directory need to create method for rendering template from base.html.eex template
  """

  @doc """
  Renders a template within a base layout.

  This function takes a template name and a keyword list of assigns, evaluates the specified template,
  and then embeds the resulting content into a base layout template.

  ## Parameters

  - `template`: The name of the template to render (without the `.html.eex` extension).
  - `assigns`: A keyword list of variables to pass to the template. Defaults to an empty list.

  ## Returns

  - A binary string containing the rendered HTML.

  ## Examples

      # Render the "index" template with custom assigns
      render("index", title: "Home", user: %{name: "John"})

      # Render the "about" template without custom assigns
      render("about")
  """
  @spec render(any(), keyword()) :: binary()
  def render(template, assigns \\ []) do
    assigns = Keyword.merge([], assigns)
    content = EEx.eval_file("templates/#{template}.html.eex", assigns)

    EEx.eval_file("templates/base.html.eex", assigns ++ [content: content])
  end

  @doc """
  Renders a standalone template without a base layout.

  This function takes a template name and a keyword list of assigns, evaluates the specified template,
  and returns the resulting content as a binary string.

  ## Parameters

  - `template`: The name of the template to render (without the `.html.eex` extension).
  - `assigns`: A keyword list of variables to pass to the template. Defaults to an empty list.

  ## Returns

  - A binary string containing the rendered HTML.

  ## Examples

      # Render the "header" template with custom assigns
      layout_render("header", title: "Welcome")

      # Render the "footer" template without custom assigns
      layout_render("footer")
  """
  @spec layout_render(any(), keyword()) :: binary()
  def layout_render(template, assigns \\ []) do
    EEx.eval_file("templates/#{template}.html.eex", assigns)
  end


end
