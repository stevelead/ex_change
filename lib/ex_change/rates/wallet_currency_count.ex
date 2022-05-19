defmodule ExChange.Rates.WalletCurrencyCount do
  defstruct ticker: nil, count: 0

  alias ExChange.Rates.WalletCurrencyCount

  def new(ticker, count \\ 0) do
    %WalletCurrencyCount{ticker: ticker, count: count}
  end
end
