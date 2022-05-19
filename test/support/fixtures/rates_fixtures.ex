defmodule Support.Fixtures.RatesFixtures do
  alias ExChange.Rates.Rate
  alias ExChange.Rates.WalletCurrencyCount

  @default_rate_params %{code: "NZD/USD", rate: 0.55}
  @currency_count_params %{ticker: "NZD", count: 5}

  def rate_fixture(params \\ @default_rate_params) do
    Rate.new(params.code, params.rate)
  end

  def wallet_currency_count_fixture(params \\ @currency_count_params) do
    WalletCurrencyCount.new(params.ticker, params.count)
  end
end
