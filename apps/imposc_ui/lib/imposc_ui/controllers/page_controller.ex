defmodule ImposcUi.PageController do
  use ImposcUi, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
