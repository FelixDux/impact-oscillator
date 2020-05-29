defmodule ImposcUi.PageController do
  use ImposcUi, :controller

  def index(conn, _params) do
    actions =
      ActionMap.list_actions()
      |> Enum.map(fn {name, description} -> %{name: name, description: description} end)

    render(conn, "index.html", actions: actions)
  end
end
