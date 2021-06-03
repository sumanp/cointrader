defmodule CointraderWeb.CryptoDashboardLive do #each concurrent user has their own process
  use CointraderWeb, :live_view
  alias Cointrader.Product
  import CointraderWeb.ProductHelpers

  @impl true
  def mount(_params, _session, socket) do # entry point
    socket = assign(socket, trades: %{}, products: [], filter_products: & &1)
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

  @impl true
  def handle_event("add-product", %{"product_id" => product_id} =_params, socket) do
    [exchange_name, currency_pair] = String.split(product_id, ":")
    product = Product.new(exchange_name, currency_pair)
    socket = maybe_add_product(socket, product)
    {:noreply, socket}
  end

  def handle_event("clear", _event, socket) do
    socket = assign(socket, :trades, %{})
    {:noreply, socket}
  end

  def handle_event("filter-products", %{"search" => search}, socket) do
    socket =
      assign(socket, :filter_products, fn product ->
        String.downcase(product.exchange_name) =~ String.downcase(search) or
          String.downcase(product.currency_pair) =~ String.downcase(search)
      end)

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
      socket
      |> add_product(product)
      |> put_flash(
        :info,
        "#{product.exchange_name} - #{product.currency_pair} added successfully"
      )
    else
      socket
      |> put_flash(:error, "The product was already added")
    end
  end
end
