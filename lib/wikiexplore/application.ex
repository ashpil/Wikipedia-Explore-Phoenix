defmodule Wikiexplore.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      # Start the Telemetry supervisor
      WikiexploreWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: Wikiexplore.PubSub},
      # Start the Endpoint (http/https)
      WikiexploreWeb.Endpoint
      # Start a worker by calling: Wikiexplore.Worker.start_link(arg)
      # {Wikiexplore.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Wikiexplore.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    WikiexploreWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
