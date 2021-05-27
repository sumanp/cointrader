defmodule Cointrader.Exchanges.Supervisor do #dedicated supervisor for exchnage clients
  use Supervisor
  alias Cointrader.Exchanges

  def start_link(opts) do
    {clients, opts}= Keyword.pop(opts, :clients, Exchanges.clients())
    Supervisor.start_link(__MODULE__, clients, opts)
  end

  def init(clients) do
    Supervisor.init(clients, strategy: :one_for_one) #restart exchange client process if it fails
  end
end
