defmodule Cointrader.Historical do
  use GenServer
  alias Cointrader.{Product, Trade, Exchanges}

  @type t() :: %__MODULE__{
    products: [Product.t()],
    trades: %{Product.t() => Trade.t()}
  }

  defstruct [:products, :trades]

  @spec get_last_trade(pid() | atom(), Product.t()) :: Trade.t() | nil
  def get_last_trade(pid\\__MODULE__, product) do # public API to fetch last trade of currency pair
    GenServer.call(pid, {:get_last_trade, product})
  end

  def start_link(opts) do
    {products, opts} = Keyword.pop(opts, :products, []) # defaults to empty list if opts absent
    GenServer.start_link(__MODULE__, products, opts)
  end

  def init(products) do
    historical = %__MODULE__{products: products, trades: %{}}
    {:ok, historical, {:continue, :subscribe}}
  end

  def handle_continue(:subscribe, historical) do #subscribe to phoenix pubsub
    Enum.each(historical.products, &Exchanges.subscribe/1)
    {:noreply, historical}
  end

  def handle_info({:new_trade, trade}, historical) do
    updated_trades = Map.put(historical.trades, trade.product, trade)
    updated_historical = %{historical | trades: updated_trades}
    {:noreply, updated_historical}
  end

  def handle_call({:get_last_trade, product}, _from, historical) do # call expects 3 arguments
    trade = Map.get(historical.trades, product)
    {:reply, trade, historical}
  end

end
