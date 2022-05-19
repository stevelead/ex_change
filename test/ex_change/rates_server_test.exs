defmodule ExChange.RatesServerTest do
  use ExUnit.Case
  import Support.Fixtures.RatesApiFixtures
  require Decimal

  alias ExChange.RatesServer
  alias ExChange.RatesApi

  describe "RatesServer.start_link/1" do
    test "accepts a name on start and creates entry in Registry", %{test: test} do
      assert {:ok, pid} = RatesServer.start_link(name: test)

      assert [{^pid, _key}] = Registry.lookup(ExChange.Registry, test)
    end

    test "accepts initial state on start", %{test: test} do
      rates = [rates_fixture()]
      currency_count = wallet_currency_count_fixture()
      initial_state = %{rates: rates, currency_count: currency_count}

      assert {:ok, _pid} = RatesServer.start_link(name: test, initial_state: initial_state)

      assert state = RatesServer.get_state(test)
      assert state.rates == rates
    end

    test "accepts rates api module on start", %{test: test} do
      rates_api_module = RatesApi.Mock
      initial_state = %{rates_api_module: rates_api_module}

      assert {:ok, _pid} = RatesServer.start_link(name: test, initial_state: initial_state)

      assert state = RatesServer.get_state(test)
      assert state.rates_api_module == rates_api_module
    end

    test "accepts rates an initial tick rate on start", %{test: test} do
      tick_rate = 100
      initial_state = %{tick_rate: tick_rate}

      assert {:ok, _pid} = RatesServer.start_link(name: test, initial_state: initial_state)

      assert state = RatesServer.get_state(test)
      assert state.tick_rate == tick_rate
    end
  end

  describe "RatesServer calls the exchange rate api" do
    test "a call is made at the tick rate", %{test: test} do
      currency_count =
        wallet_currency_count_fixture([%{ticker: "NZD", count: 5}, %{ticker: "USD", count: 5}])

      initial_state = %{
        currency_count: currency_count,
        rates_api_module: RatesApi.Mock,
        tick_rate: 10
      }

      opts = [
        name: test,
        initial_state: initial_state
      ]

      assert {:ok, _pid} = RatesServer.start_link(opts)

      Process.sleep(15)

      assert state = RatesServer.get_state(test)
      assert 0.65 = get_float_rate(state.rates, "NZD:USD")
      assert state.rates |> get_rate("USD:NZD") |> Decimal.is_decimal()
    end
  end

  defp get_float_rate(rates, code) do
    rates
    |> get_rate(code)
    |> Decimal.to_float()
  end

  defp get_rate(rates, code) do
    rates |> Map.get(code) |> Map.get(:rate)
  end
end
