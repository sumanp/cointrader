defmodule Cointrader do
  @moduledoc """
  Cointrader keeps the contexts that define your domain
  and business logic.

  Contexts are also responsible for managing your data, regardless
  if it comes from the database, an external API or others.
  """

  defdelegate subscribe_to_trades(product),
    to: Cointrader.Exchanges, as: :subscribe

  defdelegate unsubscribe_from_trades(product),
    to: Cointrader.Exchanges, as: :unsubscribe

  defdelegate get_last_trade(product), to: Cointrader.Historical

  defdelegate get_last_trades(products), to: Cointrader.Historical

  defdelegate available_products(), to: Cointrader.Exchanges

end
