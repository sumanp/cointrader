defmodule CointraderWeb.CryptoDashboardLive do #each concurrent user has their own process
  use CointraderWeb, :live_view
  alias Cointrader.Product
  import CointraderWeb.ProductHelpers
  alias CointraderWeb.Router.Helpers, as: Routes

  @impl true
  def mount(params, _session, socket) do # entry point
    socket =
      socket
      |> assign(products: [], filter_products: & &1, timezone: get_timezone_from_connection(socket))
      |> add_products_from_params(params)

    {:ok, socket}
  end

  @impl true
  def handle_params(_params, _uri, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_info({:new_trade, trade}, socket) do # view re-render with change in assign
    send_update(CointraderWeb.ProductComponent, id: trade.product, trade: trade)
    {:noreply, socket}
  end

  @impl true
  def handle_event("add-product", %{"product_id" => product_id} =_params, socket) do
    [exchange_name, currency_pair] = String.split(product_id, ":")
    product = Product.new(exchange_name, currency_pair)
    socket =
      socket
      |> maybe_add_product(product)
      |> update_products_params()
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
    Cointrader.unsubscribe_from_trades(product)
    socket =
      socket
      |> update(:products, &List.delete(&1, product))
      |> update_products_params()
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

  defp update_products_params(socket) do
    product_ids = Enum.map(socket.assigns.products, &to_string/1)
    push_patch(socket, to: Routes.live_path(socket, __MODULE__, products: product_ids))
  end

  defp add_products_from_params(socket, %{"products" => product_ids} = _params) when is_list(product_ids) do
    products = Enum.map(product_ids, &product_from_string/1)

    Enum.reduce(products, socket, fn product, socket ->
      maybe_add_product(socket, product)
    end)
  end

  defp add_products_from_params(socket, _params), do: socket

end
