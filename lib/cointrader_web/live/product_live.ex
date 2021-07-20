#lib/cointrader_web/live/product_live.ex
defmodule CointraderWeb.ProductLive do
  use CointraderWeb, :live_view
  import CointraderWeb.ProductHelpers

  def mount(%{"id" => product_id} = _params, _session, socket) do
    product = product_from_string(product_id)
    trade = Cointrader.get_last_trade(product)
    trades = get_trade_history()

    socket =
      assign(socket,
        product: product,
        product_id: product_id,
        trade: trade,
        trades: trades,
        page_title: page_title_from_trade(trade)
      )

    if socket.connected? do # subscribe to new trades: handled by handle_info/2 callback
      Cointrader.subscribe_to_trades(product)
    end

    {:ok, socket, temporary_assigns: [trades: []]} #reset/empty trade list on each render
  end

  def render(%{trade: trade} = assigns) when not is_nil(trade) do
    ~L"""
    <div>
      <h1><%= fiat_character(@product) %> <%= @trade.price %></h1>
      <p>Traded at <%= human_datetime(@trade.traded_at) %></p>
    </div>
    <div class="column">
      <div class="column">
        <table>
          <thead>
            <th>Time</th>
            <th>Price</th>
            <th>Volume</th>
          </thead>
          <tbody phx-update="prepend" id="trade-history-rows">
            <%= for trade <- @trades do %>
              <tr id="trade-<%= timestamp(trade.traded_at) %>">
                <td><%= trade.traded_at %></td>
                <td><%= trade.price %></td>
                <td><%= trade.volume %></td>
              </tr>
            <% end %>
          </tbody>
        </table>
      </div>
    </div>
    """
  end

  def render(assigns) do
    ~L"""
    <div>
      <h1><%= fiat_character(@product) %> ...</h1>
    </div>
    """
  end

  def handle_info({:new_trade, trade}, socket) do
    socket =
      socket
      |> assign(:trade, trade)
      |> update(:trades, & [trade | &1])
      |> assign(:page_title, page_title_from_trade(trade))

    {:noreply, socket}
  end

  defp page_title_from_trade(trade) do
    "#{fiat_character(trade.product)}#{trade.price}" <>
      " #{trade.product.currency_pair} #{trade.product.exchange_name}"
  end

  defp timestamp(dt) do
    DateTime.to_unix(dt, :millisecond)
  end

  defp get_trade_history do
    []
  end
end
