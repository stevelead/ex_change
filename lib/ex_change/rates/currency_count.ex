defmodule ExChange.Rates.CurrencyCount do
  defstruct ticker: nil, count: 0

  alias ExChange.Rates.CurrencyCount

  def new(ticker, count \\ 0) do
    %CurrencyCount{ticker: ticker, count: count}
  end

  def add_currency(new_item, collection) do
    Map.update(collection, new_item.ticker, 0, &(&1 + 1))
  end
end
