defmodule ExChange.RatesTest do
  use ExUnit.Case
  require Decimal

  alias ExChange.Rates
  alias ExChange.Rates.Rate
  alias ExChange.Rates.RatesApiMock

  describe "Rates.start_link/1" do
    test "accepts a name on start and creates entry in Registry", %{test: test} do
      assert {:ok, pid} = Rates.start_link(name: test)
      assert [{^pid, _key}] = Registry.lookup(ExChange.Registry, test)
    end

    test "accepts initial state on start", %{test: test} do
      rates_api_module = RatesApiMock
      rates = [Rate.new("NZD/USD", 0.55)]
      initial_state = %{rates: rates, wallet_tickers: [], rates_api_module: rates_api_module}

      assert {:ok, _pid} = Rates.start_link(name: test, initial_state: initial_state)
      assert state = Rates.state(test)
      assert state.rates == rates
      assert state.rates_api_module == rates_api_module
    end
  end

  describe "Rates.Rate.new/3" do
    test "accepts a rate as binary and returns a Decimal" do
      assert %{rate: rate} = Rate.new("NZD/USD", ".65")
      assert Decimal.is_decimal(rate)
    end

    test "accepts a rate as float and returns a Decimal" do
      assert %{rate: rate} = Rate.new("NZD/USD", 0.65)
      assert Decimal.is_decimal(rate)
    end
  end
end
