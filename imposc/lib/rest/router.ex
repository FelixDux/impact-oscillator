defmodule Imposc.Router do
  use Plug.Router

  plug(:match)
  plug(:dispatch)

  get "/" do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, JSON.encode!(actions()))
  end

  get "/info/:action" do
    if Map.has_key?(actions() |> Map.new(), action) do
      action_info(action) |> send_json(conn)
    else
      conn |> report_unmatched("/info/#{action}")
    end
  end

  get "/images/:image" do
    image_type = image |> Path.extname() |> String.replace(".", "")
    content_type = "image/#{image_type}"

    case ImageCache.cache_path(%ImageCache{}) do
      {:ok, image_dir} ->
        (fn ->
           file_path = [image_dir, Path.basename(image)] |> Path.join()

           conn
           |> put_resp_content_type(content_type)
           |> send_resp(200, File.read!(file_path))
         end).()

      _ ->
        conn |> report_unmatched("/info/#{image}")
    end
  end

  post "/action" do
    json_key = "_json"

    if Map.has_key?(conn.body_params, json_key) do
      Map.fetch!(conn.body_params, json_key) |> CoreWrapper.process() |> send_json(conn)
    else
      send_resp(conn, 422, "Could not retrieve JSON from POST request")
    end
  end

  defp send_json(json, conn) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, JSON.encode!(json))
  end

  defp actions do
    #    %{
    # response_type: "in_channel",
    # text: "Hello from BOT :)"
    # }
    ActionMap.list_actions()
  end

  defp action_info(action) do
    ActionMap.action_info(action)
  end

  defp report_unmatched(conn, endpoint) do
    send_resp(conn, 404, "Unregonised endpoint: #{endpoint}")
  end

  defp path_to_endpoint(p) do
    p
    |> Path.dirname()
    |> Path.split()
    |> Enum.reverse()
    |> (&with([h | _] <- &1, do: h)).()
    |> (&([&1] ++ [Path.basename(p)])).()
    |> Path.join()
  end
end
