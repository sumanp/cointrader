defmodule Cointrader.Exchanges.CoinbaseClient do
  use GenServer
  alias Cointrader.{Trade, Product}

  @exchange_name "coinbase"

  def start_link(currency_pairs, options \\[]) do
    GenServer.start_link(__MODULE__, currency_pairs, options)
  end

  def init(currency_pairs) do #seperate connection concern from init
    state = %{
      currency_pairs: currency_pairs,
      conn: nil
    }
    {:ok, state, {:continue, :connect}}
  end

  def handle_continue(:connect, state) do
    updated_state = connect(state)
    {:noreply, updated_state}
  end

  def server_host, do: 'ws-feed.pro.coinbase.com'

  def server_port, do: 443

  def connect(state) do
    {:ok, conn} = :gun.open(server_host(), server_port(), %{protocols: [:http]})
    %{state | conn: conn}
  end

  def handle_info({:gun_up, conn, :http}, %{conn: conn}=state) do #ensure same connection
    :gun.ws_upgrade(conn, "/")
    {:noreply, state}
  end

  def handle_info({:gun_upgrade, conn, _ref, ["websocket"], _headers}, %{conn: conn}=state) do
    subscribe(state)
    {:noreply, state}
  end

  def handle_info({:gun_ws, conn, _ref, {:text, msg}=_frame}, %{conn: conn}=state) do
    handle_ws_message(Jason.decode!(msg), state)
  end

  def handle_ws_message(%{"type" => "ticker"}=msg, state) do
      msg
      |> message_to_trade()
      |> IO.inspect(label: "trade")

    {:noreply, state}
  end

  def handle_ws_message(msg, state) do
    IO.inspect(msg, label: "unhandeled message")
    {:noreply, state}
  end

  def subscribe(state) do
    subscription_frames(state.currency_pairs)
    |> Enum.each(&:gun.ws_send(state.conn, &1))
  end

  def subscription_frames(currency_pairs) do
    msg = %{
      "type" => "subscribe",
      "product_ids" => currency_pairs,
      "channels" => ["ticker"]
    } |> Jason.encode!()
    [{:text, msg}]
  end

  @spec message_to_trade(map) :: {:ok, Trade.t()} | {:error, any()}
  def message_to_trade(msg) do
    with :ok <- validate_required(msg, ["product_id", "time", "price", "last_size"]),
      {:ok, traded_at, _} <- DateTime.from_iso8601(msg["time"])
    do
    currency_pair = msg["product_id"]
    Trade.new(
      product: Product.new(@exchange_name, currency_pair),
      price: msg["price"],
      volume: msg["last_size"],
      traded_at: traded_at

    )
    else
      {:error, _reason}=error -> error
    end
  end

  @spec validate_required(map(), [String.t()]) :: :ok | {:error, {String.t(), :required}}
  def validate_required(msg, keys) do
    required_key = Enum.find(keys, fn k -> is_nil(msg[k]) end)

    if is_nil(required_key), do: :ok,
    else: {:error, {required_key, :required}}
  end
end
