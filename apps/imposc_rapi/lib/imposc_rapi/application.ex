defmodule ImposcRapi.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      # Starts a worker by calling: ImposcRapi.Worker.start_link(arg)
      # {ImposcRapi.Worker, arg}
      {Plug.Cowboy, scheme: :http, plug: ImposcRapi.Endpoint, options: [port: cowboy_port()]}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: ImposcRapi.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp cowboy_port, do: Application.get_env(:imposc, :cowboy_port, 8080)
end
