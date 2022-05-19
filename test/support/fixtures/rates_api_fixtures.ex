defmodule Support.Fixtures.RatesApiFixtures do
  alias ExChange.RatesApi.Rate
  alias ExChange.Wallets

  @default_rate_params [%{code: "NZD/USD", rate: "0.55"}]
  @currency_count_params [%{currency: "NZD", count: 5}]

  def rates_fixture(params \\ @default_rate_params) do
    Enum.reduce(params, %{}, fn item, acc ->
      put_new_rate(item, acc)
    end)
  end

  def wallet_currency_count_fixture(wallets \\ @currency_count_params) do
    Wallets.get_currency_count(wallets)
  end

  defp put_new_rate(item, acc) do
    {code, rest} = Rate.new(item.code, item.rate) |> Map.pop!(:code)
    Map.put(acc, code, rest)
  end
end
