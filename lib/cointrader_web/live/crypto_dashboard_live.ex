defmodule CointraderWeb.CryptoDashboardLive do #each concurrent user has their own process
  use CointraderWeb, :live_view
  alias Cointrader.Product

  @impl true
  def mount(_params, _session, socket) do # entry point
    socket = assign(socket, trades: %{}, products: [])
    {:ok, socket}
  end

  @impl true
  def handle_info({:new_trade, trade}, socket) do # view re-render with change in assign
    socket =
      socket
      |> update(:trades, &Map.put(&1, trade.product, trade))
      |> assign(:page_title, "Product List")

    {:noreply, socket}
  end


  def handle_event("add-product", %{"exchange" => exchange, "pair" => pair} =_params, socket) do
    product = Product.new(exchange, pair)
    socket = maybe_add_product(socket, product)
    {:noreply, socket}
  end

  def handle_event("clear", _event, socket) do
    socket = assign(socket, :trades, %{})
    {:noreply, socket}
  end

  def add_product(socket, product) do
    Cointrader.subscribe_to_trades(product)
    socket
    |> update(:products, & &1 ++ [product])
    |> update(:trades, fn trades ->
      trade = Cointrader.get_last_trade(product)
      Map.put(trades, product, trade)
    end)
  end

  defp maybe_add_product(socket, product) do
    if product not in socket.assigns.products do
      add_product(socket, product)
    else
      socket
    end
  end
end
