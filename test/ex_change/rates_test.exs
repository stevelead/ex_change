defmodule ExChange.RatesTest do
  use ExUnit.Case
  require Decimal
  import Support.Fixtures.RatesFixtures

  alias ExChange.Rates
  alias ExChange.Rates.RatesApiMock

  describe "Rates.start_link/1" do
    test "accepts a name on start and creates entry in Registry", %{test: test} do
      assert {:ok, pid} = Rates.start_link(name: test)

      assert [{^pid, _key}] = Registry.lookup(ExChange.Registry, test)
    end

    test "accepts initial state on start", %{test: test} do
      rates = [rate_fixture()]
      initial_state = %{rates: rates}

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
end
