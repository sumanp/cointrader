defmodule Cointrader.Exchanges do # Exchange context public functions
  alias Cointrader.{Product, Trade}

  @clients [ #module attribute
    Cointrader.Exchanges.CoinbaseClient,
    Cointrader.Exchanges.BitstampClient
  ]

  # static list, compute only once, at compile time
  @available_products (for client <- @clients, pair <- client.available_currency_pairs do
    Product.new(client.exchange_name(), pair)
  end)

  @spec clients() :: [module()]
  def clients, do: @clients

  @spec available_products() :: [Product.t()]
  def available_products(), do: @available_products

  @spec subscribe(Product.t()) :: :ok | {:error, term()}
  def subscribe(product) do
    Phoenix.PubSub.subscribe(Cointrader.PubSub, topic(product))
  end

  @spec unsubscribe(Product.t()) :: :ok | {:error, term()}
  def unsubscribe(product) do
    Phoenix.PubSub.unsubscribe(Cointrader.PubSub, topic(product))
  end

  @spec broadcast(Trade.t()) :: :ok | {:error, term()}
  def broadcast(trade) do
    Phoenix.PubSub.broadcast(Cointrader.PubSub, topic(trade.product), {:new_trade, trade})
  end

  @spec topic(Product.t()) :: String.t()
  defp topic(product) do
    to_string(product)
  end
end
