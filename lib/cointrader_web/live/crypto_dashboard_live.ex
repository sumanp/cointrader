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
  def render(assigns) do
    ~L"""
    <table>
      <thead>
        <th>Traded at</th>
        <th>Exchange</th>
        <th>Currency</th>
        <th>Price</th>
        <th>Volume</th>
      </thead>
      <tbody>
      <%= for product <- @products, trade = @trades[product] do%>
        <tr>
          <td><%= trade.traded_at %></td>
          <td><%= trade.product.exchange_name %></td>
          <td><%= trade.product.currency_pair %></td>
          <td><%= trade.price %></td>
          <td><%= trade.volume %></td>
        </tr>
      <% end %>
      </tbody>
    </table>
    """
  end

  @impl true
  def handle_info({:new_trade, trade}, socket) do # view re-render with change in assign
    socket = update(socket, :trades, &Map.put(&1, trade.product, trade))
    {:noreply, socket}
  end
end
