defmodule ExChange.RatesTest do
  use ExUnit.Case
  import ExUnit.CaptureLog
  import Support.Fixtures.RatesFixtures
  require Decimal

  alias ExChange.Rates
  alias ExChange.Rates.RatesApiMock

  describe "Rates.start_link/1" do
    test "accepts a name on start and creates entry in Registry", %{test: test} do
      assert {:ok, pid} = Rates.start_link(name: test)

      assert [{^pid, _key}] = Registry.lookup(ExChange.Registry, test)
    end

    test "accepts initial state on start", %{test: test} do
      rates = [rate_fixture()]
      wallet_currency_count = [wallet_currency_count_fixture()]
      initial_state = %{rates: rates, wallet_currency_count: wallet_currency_count}

      assert {:ok, _pid} = Rates.start_link(name: test, initial_state: initial_state)

      assert state = Rates.state(test)
      assert state.rates == rates
    end

    test "accepts rates api module on start", %{test: test} do
      rates_api_module = RatesApiMock
      initial_state = %{rates_api_module: rates_api_module}

      assert {:ok, _pid} = Rates.start_link(name: test, initial_state: initial_state)

      assert state = Rates.state(test)
      assert state.rates_api_module == rates_api_module
    end

    test "accepts rates an initial tick rate on start", %{test: test} do
      tick_rate = 100
      initial_state = %{tick_rate: tick_rate}

      assert {:ok, _pid} = Rates.start_link(name: test, initial_state: initial_state)

      assert state = Rates.state(test)
      assert state.tick_rate == tick_rate
    end
  end

  describe "Rates.Rate.new/3" do
    test "accepts a rate as binary and returns a Decimal" do
      assert %{rate: rate} = rate_fixture()

      assert Decimal.is_decimal(rate)
    end

    test "accepts a rate as float and returns a Decimal" do
      assert %{rate: rate} = rate_fixture()

      assert Decimal.is_decimal(rate)
    end
  end

  describe "Rates calls the exchange rate api" do
    test "a call is made at the tick rate", %{test: test} do
      wallet_currency_count =
        [
          wallet_currency_count_fixture(%{ticker: "NZD", count: 5}),
          wallet_currency_count_fixture(%{ticker: "USD", count: 5})
        ]
        |> convert_to_map()

      initial_state = %{
        wallet_currency_count: wallet_currency_count,
        rates_api_module: RatesApiMock,
        tick_rate: 10
      }

      opts = [
        name: test,
        initial_state: initial_state
      ]

      assert {:ok, _pid} = Rates.start_link(opts)

      Process.sleep(15)

      assert state = Rates.state(test)
      assert 0.65 = get_float_rate(state.rates, "NZD:USD")
      assert state.rates |> get_rate("USD:NZD") |> Decimal.is_decimal()
    end
  end

  defp get_rate(rates, code) do
    rates |> Map.get(code) |> Map.get(:rate)
  end

  defp get_float_rate(rates, code) do
    rates
    |> get_rate(code)
    |> Decimal.to_float()
  end

  defp convert_to_map(list) do
    Enum.reduce(list, %{}, fn item, acc ->
      Map.put(acc, item.ticker, item.count)
    end)
  end
end
