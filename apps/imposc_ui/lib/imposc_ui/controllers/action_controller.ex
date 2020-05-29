defmodule ImposcUi.ActionController do
  use ImposcUi, :controller

  def index(conn, _params) do
    actions =
      ActionMap.list_actions()
      |> Enum.map(fn {name, description} -> %{name: name, description: description} end)

    render(conn, "index.html", actions: actions)
  end

  def show(conn, %{"id" => name}) do
    action = ActionMap.action_info(name) |> ActionChangeset.from_map()
    render(conn, "show.html", action: action)
  end

  def create(conn, form_params) do
    [{action, params}] = form_params |> Map.drop(["_csrf_token"]) |> Map.to_list()

    response =
      ActionChangeset.model_to_response(action, params)
      |> CoreWrapper.process()
      |> (fn r ->
            case r do
              [x] -> x
              _ -> r
            end
          end).()

    {:ok, image} = Map.fetch!(response, "result")

    image_type = image |> Path.extname() |> String.replace(".", "")
    content_type = "image/#{image_type}"

    case File.read(image) do
      {:ok, image_stream} ->
        conn
        |> put_resp_content_type(content_type)
        |> send_resp(200, image_stream)

      _ ->
        conn |> send_resp(404, "Image not found")
    end
  end
end
