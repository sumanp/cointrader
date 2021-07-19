defmodule CointraderWeb.CryptoDashboardLive do #each concurrent user has their own process
  use CointraderWeb, :live_view
  import CointraderWeb.ProductHelpers
  alias CointraderWeb.Router.Helpers, as: Routes
  require Logger

  @impl true
  def mount(_params, _session, socket) do # entry point
    socket =
      socket
      |> assign(products: [], filter_products: & &1, timezone: get_timezone_from_connection(socket))

    {:ok, socket}
  end

  @impl true
  def handle_params(%{"products" => product_ids} = _params, _uri, socket) do
    new_products = Enum.map(product_ids, &product_from_string/1)
    diff = List.myers_difference(socket.assigns.products, new_products)
    products_to_remove = diff |> Keyword.get_values(:del) |> List.flatten()
    products_to_insert = diff |> Keyword.get_values(:ins) |> List.flatten()

    socket =
      Enum.reduce(products_to_remove, socket, fn product, socket ->
        remove_product(socket, product)
      end)

    socket =
      Enum.reduce(products_to_insert, socket, fn product, socket ->
        add_product(socket, product)
      end)

    {:noreply, socket}
  end

  def handle_params(params, _uri, socket) do
    Logger.debug("Unhandled params: #{inspect(params)}")
    {:noreply, socket}
  end


  @impl true
  def handle_info({:new_trade, trade}, socket) do # view re-render with change in assign
    send_update(CointraderWeb.ProductComponent, id: trade.product, trade: trade)
    {:noreply, socket}
  end

  @impl true
  def handle_event("add-product", %{"product_id" => product_id} =_params, socket) do
    product_ids =
      socket.assigns.products
      |> Enum.map(&to_string/1)
      |> Kernel.++([product_id]) # update existing list
      |> Enum.uniq()

    socket = push_patch(socket,
      to: Routes.live_path(socket, __MODULE__, products: product_ids))

      {:noreply, socket}
  end

  def handle_event("add-product", _, socket) do
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
    product_ids =
      socket.assigns.products
      |> Enum.map(&to_string/1)
      |> Kernel.--([product_id]) # remove & update existing list
      |> Enum.uniq()

    socket = push_patch(socket,
      to: Routes.live_path(socket, __MODULE__, products: product_ids))

    {:noreply, socket}
  end

  def add_product(socket, product) do
    Cointrader.subscribe_to_trades(product)
    socket
    |> update(:products, &(&1 ++ [product]))
  end

  def remove_product(socket, product) do
    Cointrader.unsubscribe_from_trades(product)
    socket
    |> update(:products, &(&1 -- [product]))
  end

  defp get_timezone_from_connection(socket) do
    case get_connect_params(socket) do
      %{"timezone" => tz} when not is_nil(tz) -> tz
      _ -> "UTC"
    end
  end
end
