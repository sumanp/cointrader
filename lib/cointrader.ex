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
end
