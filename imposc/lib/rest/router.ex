defmodule Imposc.Router do
  use Plug.Router

  plug(:match)
  plug(:dispatch)

  get "/" do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, JSON.encode!(actions()))
  end

  defp actions do
    #    %{
    # response_type: "in_channel",
    # text: "Hello from BOT :)"
    # }
    ActionMap.list_actions()
  end
end
