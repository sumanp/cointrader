defmodule CointraderWeb.CryptoDashboardLive do #each concurrent user has their own process
  use CointraderWeb, :live_view
  alias Cointrader.Product
  import CointraderWeb.ProductHelpers

  @impl true
  def mount(_params, _session, socket) do # entry point
    socket = assign(socket, products: [], filter_products: & &1,
              timezone: get_timezone_from_connection(socket))
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"product_id" => product_id}=_params, _uri, socket) do
    product = product_from_string(product_id)
    socket =
      socket
      |> assign(:selected_product, product) # update socket
      |> maybe_update_title_with_trade(Cointrader.get_last_trade(product)) # update socket

    {:noreply, socket}
  end

  def handle_params(_params, _uri, socket), do: {:noreply, socket}

  @impl true
  def handle_info({:new_trade, trade}, socket) do # view re-render with change in assign
    send_update(CointraderWeb.ProductComponent, id: trade.product, trade: trade)

    socket =
      socket
      |> maybe_update_title_with_trade(trade)

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

  def handle_event("remove-product", %{"product-id" => product_id} = _params, socket) do
    product = product_from_string(product_id)
    socket = update(socket, :products, &List.delete(&1, product))
    {:noreply, socket}
  end

  def add_product(socket, product) do
    Cointrader.subscribe_to_trades(product)
    socket
    |> update(:products, & &1 ++ [product])
  end

  defp maybe_add_product(socket, product) do
    if product not in socket.assigns.products do
      socket
      |> add_product(product)
    else
      socket
    end
  end

  defp product_from_string(product_id) do
    [exchange_name, currency_pair] = String.split(product_id, ":")
    Product.new(exchange_name, currency_pair)
  end

  defp get_timezone_from_connection(socket) do
    case get_connect_params(socket) do
      %{"timezone" => tz} when not is_nil(tz) -> tz
      _ -> "UTC"
    end
  end

  defp maybe_update_title_with_trade(%{assigns: %{selected_product: product}}=socket, %{product: product}=trade) do
    assign(socket, :page_title, "#{trade.price} - #{product.currency_pair}")
  end

  defp maybe_update_title_with_trade(socket, _trade), do: socket
end
