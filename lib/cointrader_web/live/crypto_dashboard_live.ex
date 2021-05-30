defmodule CointraderWeb.CryptoDashboardLive do #each concurrent user has their own process
  use CointraderWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do # entry point
    products = Cointrader.available_products()
    trades =
      products
      |> Cointrader.get_last_trades()
      |> Enum.reject(&is_nil(&1))
      |> Enum.map(& {&1.product, &1})
      |> Enum.into(%{})

    if socket.connected? do # socket connection is false before the hand-shake
      Enum.each(products, &Cointrader.subscribe_to_trades(&1))
    end

    socket = assign(socket, trades: trades, products: products)
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
end
