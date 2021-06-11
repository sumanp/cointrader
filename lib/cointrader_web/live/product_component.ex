defmodule CointraderWeb.ProductComponent do
  use CointraderWeb, :live_component
  import CointraderWeb.ProductHelpers

  # optional callbacks for stateless components

  def update(%{trade: trade}=_assigns, socket) when not is_nil(trade) do
    socket = assign(socket, :trade, trade)
    {:ok, socket}
  end

  def update(assigns, socket) do
    product = assigns.id
    socket =
      assign(socket,
        product: product,
        trade: Cointrader.get_last_trade(product),
        timezone: assigns.timezone
      )
    {:ok, socket}
  end

  # optional callbacks close

  def render(%{trade: trade}=assigns) when not is_nil(trade) do
    ~L"""
      <div class="product-component">
        <button class="remove" phx-click="remove-product"
          phx-value-product-id="<%= to_string(@product)%>">X</button>
        <div class="currency-container">
          <img class="icon" src="<%= crypto_icon(@socket, @product) %>" />
          <div class="crypto-name">
            <%= crypto_name(@product) %>
          </div>
        </div>

        <div class="price-container">
          <ul class="fiat-symbols">
            <%= for fiat <- fiat_symbols() do %>
              <li class="
              <%= if fiat_symbol(@product) == fiat, do: "active" %>
                "><%= fiat %></li>
            <% end %>
          </ul>

          <div class="price">
            <%= @trade.price %>
            <%= fiat_character(@product) %>
          </div>
        </div>

        <div class="chart-component">
          <div phx-hook="Chart"
              id="product-chart-<%= to_string(@product) %>"
              data-price="<%= @trade.price %>"
              data-traded-at="<%= DateTime.to_unix(@trade.traded_at, :millisecond) %>"
              phx-update="ignore"
            >
            <div class="chart-container"></div>
          </div>
        </div>

        <div class="exchange-name">
          <%= @product.exchange_name %>
        </div>

        <div class="trade-time">
          <%= human_datetime(@trade.traded_at, @timezone) %>
        </div>
      </div>
    """
  end

  def render(assigns) do
    ~L"""
      <div class="product-component">
        <div class="currency-container">
          <img class="icon" src="<%= crypto_icon(@socket, @product) %>" />
          <div class="crypto-name">
            <%= crypto_name(@product) %>
          </div>
        </div>

        <div class="price-container">
          <ul class="fiat-symbols">
            <%= for fiat <- fiat_symbols() do %>
              <li class="
              <%= if fiat_symbol(@product) == fiat, do: "active" %>
                "><%= fiat %></li>
            <% end %>
          </ul>

          <div class="price">
            ...
            <%= fiat_character(@product) %>
          </div>
        </div>

        <div class="exchange-name">
          <%= @product.exchange_name %>
        </div>

        <div class="trade-time">
        </div>
      </div>
    """
  end
end
