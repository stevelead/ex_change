defmodule ExChange.Wallets do
  def list_wallets() do
    []
  end

  def get_currency_count(wallets_list) do
    wallets_list
    |> Enum.reduce(%{}, &add_currency/2)
  end

  def add_currency(wallet, currency_count) do
    Map.update(currency_count, wallet.currency, 0, &(&1 + 1))
  end

  def get_exchange_combinations(currency_count) do
    held_currencies = Map.keys(currency_count)

    for from <- held_currencies, to <- held_currencies, from !== to do
      {from, to}
    end
  end
end
