defmodule Cointrader.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      # Start the Telemetry supervisor
      CointraderWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: Cointrader.PubSub},
      {Cointrader.Historical, name: Cointrader.Historical},
      {Cointrader.Exchanges.Supervisor, name: Cointrader.Exchanges.Supervisor},
      # Start the Endpoint (http/https)
      CointraderWeb.Endpoint
      # Start a worker by calling: Cointrader.Worker.start_link(arg)
      # {Cointrader.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Cointrader.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    CointraderWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
