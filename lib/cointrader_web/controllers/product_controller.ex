defmodule CointraderWeb.ProductController do
  use CointraderWeb, :controller

  def index(conn, _params) do
    trades =
      Cointrader.available_products()
      |> Cointrader.get_last_trades()

    render(conn, "index.html", trades: trades)
  end

end
