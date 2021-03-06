defmodule ImposcUi.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      # Start the Telemetry supervisor
      ImposcUi.Telemetry,
      # Start the Endpoint (http/https)
      ImposcUi.Endpoint,
      # Start a worker by calling: ImposcUi.Worker.start_link(arg)
      # {ImposcUi.Worker, arg}
      # Start the PubSub system
      {Phoenix.PubSub, name: ImposcUi.PubSub}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: ImposcUi.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    ImposcUi.Endpoint.config_change(changed, removed)
    :ok
  end
end
