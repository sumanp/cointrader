defmodule Cointrader.Historical do
  use GenServer
  alias Cointrader.{Product, Trade, Exchanges}

  @type t() :: %__MODULE__{ products: [Product.t()] }

  defstruct [:products]

  @ets_table_name :historical

  @spec get_last_trade(Product.t()) :: Trade.t() | nil
  def get_last_trade(product) do # public API to fetch last trade of currency pair
    case :ets.lookup(@ets_table_name, product) do
      [{^product, trade}] -> trade
      [] -> nil
    end
  end

  @spec get_last_trades([Product.t()]) :: [Trade.t()]
  def get_last_trades(products) do
    or_condition =
      Enum.reduce(products, {:or}, fn product, acc ->
        Tuple.append(acc, {:==, :"$1", product})
      end)

    ms = [
      {
        {:"$1", :"$2"},
        [or_condition],
        [:"$2"]
      }
    ]

    :ets.select(@ets_table_name, ms)
  end

  def start_link(opts) do
    {products, opts} = Keyword.pop(opts, :products, Exchanges.available_products()) # defaults to list of products across exchanges
    GenServer.start_link(__MODULE__, products, opts)
  end

  def init(products) do #table is owned by the process that created it; also process dependent deletion
    :ets.new(@ets_table_name, [:set, :protected, :named_table]) # can act as a queue
    historical = %__MODULE__{products: products}
    {:ok, historical, {:continue, :subscribe}}
  end

  def handle_continue(:subscribe, historical) do #subscribe to phoenix pubsub
    Enum.each(historical.products, &Exchanges.subscribe/1)
    {:noreply, historical}
  end

  def handle_info({:new_trade, trade}, historical) do
    :ets.insert(@ets_table_name, {trade.product, trade})
    {:noreply, historical}
  end

  def handle_call({:get_last_trades, products}, _from, historical) do # call expects 3 arguments
    trades = Enum.map(products, &Map.get(historical.trades, &1))
    {:reply, trades, historical}
  end

end
