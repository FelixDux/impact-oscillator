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
      # conn
      # |> put_resp_content_type("application/json")
      # |> send_resp(200, JSON.encode!(action_info(action)))
      action_info(action) |> send_json(conn)
    else
      conn |> report_unmatched("/info/#{action}")
    end
  end

  post "/action" do
    json_key = "_json"

    if Map.has_key?(conn.body_params, json_key) do
      content = Map.fetch!(conn.body_params, json_key) |> CoreWrapper.process() |> send_json(conn)
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
end
