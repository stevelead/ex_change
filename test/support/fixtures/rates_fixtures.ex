defmodule Support.Fixtures.RatesFixtures do
  alias ExChange.Rates.Rate
  alias ExChange.Rates.CurrencyCount

  @default_rate_params [%{code: "NZD/USD", rate: 0.55}]
  @currency_count_params [%{ticker: "NZD", count: 5}]

  def rate_fixture(params \\ @default_rate_params) do
    Enum.reduce(params, %{}, fn item, acc ->
      put_new_rate(item, acc)
    end)
  end

  def wallet_currency_count_fixture(params \\ @currency_count_params) do
    params
    |> Enum.map(&CurrencyCount.new(&1.ticker, &1.count))
    |> Enum.reduce(
      %{},
      fn item, acc ->
        Map.update(acc, item.ticker, 0, &(&1 + 1))
      end
    )
  end

  defp put_new_rate(item, acc) do
    {code, rest} = Rate.new(item.code, item.rate) |> Map.pop!(:code)
    Map.put(acc, code, rest)
  end
end
