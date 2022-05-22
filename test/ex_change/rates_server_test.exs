defmodule ExChange.RatesServerTest do
  use ExChange.DataCase

  import ExChange.RatesApiFixtures
  require Decimal

  alias ExChange.RatesServer
  alias ExChange.RatesApi
  import ExChange.WalletsFixtures
  import ExChange.AccountsFixtures

  describe "RatesServer.start_link/1" do
    test "accepts a name on start and creates entry in Registry", %{test: test} do
      assert {:ok, pid} = start_supervised({RatesServer, [name: test]})

      assert [{^pid, _key}] = Registry.lookup(ExChange.Registry, test)
    end

    test "accepts initial state on start", %{test: test} do
      rates = [rates_fixture()]
      currency_count = wallet_currency_count_fixture()

      initial_state = %{
        rates: rates,
        currency_count: currency_count,
        rates_api_module: RatesApi.Mock
      }

      assert {:ok, _pid} =
               start_supervised({RatesServer, [name: test, initial_state: initial_state]})

      assert state = RatesServer.get_state(test)
      assert state.rates == rates
    end

    test "accepts api module on start", %{test: test} do
      initial_state = %{rates_api_module: RatesApi.Mock}

      assert {:ok, _pid} =
               start_supervised({RatesServer, [name: test, initial_state: initial_state]})

      assert state = RatesServer.get_state(test)
      assert state.rates_api_module == initial_state.rates_api_module
    end

    test "accepts an initial tick rate on start", %{test: test} do
      tick_rate = 100
      initial_state = %{tick_rate: tick_rate, rates_api_module: RatesApi.Mock}

      assert {:ok, _pid} =
               start_supervised({RatesServer, [name: test, initial_state: initial_state]})

      assert state = RatesServer.get_state(test)
      assert state.tick_rate == tick_rate
    end
  end

  describe "RatesServer.init/1" do
    test "adds the currency count to state", %{test: test} do
      user = user_fixture()

      for currency <- ["NZD", "CAD"] do
        wallet_fixture(currency: currency, user_id: user.id)
      end

      user2 = user_fixture(%{email: "some@other.email"})

      for currency <- ["NZD", "USD"] do
        wallet_fixture(currency: currency, user_id: user2.id)
      end

      initial_state = %{
        rates_api_module: RatesApi.Mock
      }

      opts = [
        name: test,
        initial_state: initial_state
      ]

      assert {:ok, _pid} = start_supervised({RatesServer, opts})

      assert state = RatesServer.get_state(test)
      assert 2 = Map.get(state.currency_count, "NZD")
      assert 1 = Map.get(state.currency_count, "USD")
      assert 1 = Map.get(state.currency_count, "CAD")
    end
  end

  describe "RatesServer.add_currency/2" do
    test "adds a currency to the state currency count", %{test: test} do
      currency_count =
        wallet_currency_count_fixture([%{currency: "NZD", count: 5}, %{currency: "USD", count: 5}])

      initial_state = %{
        currency_count: currency_count,
        rates_api_module: RatesApi.Mock
      }

      opts = [
        name: test,
        initial_state: initial_state
      ]

      assert {:ok, _pid} = start_supervised({RatesServer, opts})
      assert wallet = wallet_fixture(currency: "CAD")

      :ok = RatesServer.add_currency(wallet, test)
      assert state = RatesServer.get_state(test)
      assert 1 = Map.get(state.currency_count, "CAD")
    end
  end

  describe "RatesServer.get_exchange_rate/2" do
    test "returns the current rate from state", %{test: test} do
      user = user_fixture()

      for currency <- ["NZD", "USD"] do
        wallet_fixture(%{currency: currency, user_id: user.id})
      end

      initial_state = %{
        rates_api_module: RatesApi.Mock
      }

      opts = [
        name: test,
        initial_state: initial_state
      ]

      assert {:ok, pid} = start_supervised({RatesServer, opts})

      Process.send(pid, :tick, [])

      assert decimal = RatesServer.get_exchange_rate("NZD:USD", test)
      assert "0.65" = Decimal.to_string(decimal)
    end
  end

  describe "RatesServer" do
    test "calls the exchange rate api at the tick rate", %{test: test} do
      user = user_fixture()

      for currency <- ["NZD", "USD"] do
        wallet_fixture(%{currency: currency, user_id: user.id})
      end

      initial_state = %{
        rates_api_module: RatesApi.Mock,
        tick_rate: 100
      }

      opts = [
        name: test,
        initial_state: initial_state
      ]

      assert {:ok, _pid} = start_supervised({RatesServer, opts})

      Process.sleep(150)

      assert state = RatesServer.get_state(test)
      assert Decimal.new("0.65") == get_rate_param(state.rates, "NZD:USD", :rate)
      assert state.rates |> get_rate_param("USD:NZD", :rate) |> Decimal.is_decimal()
    end

    test "does not set a new rate if a more recent rate exists", %{test: test} do
      user = user_fixture()

      for currency <- ["NZD", "USD"] do
        wallet_fixture(%{currency: currency, user_id: user.id})
      end

      rate = Decimal.new(1)
      time_updated = DateTime.utc_now() |> DateTime.add(1, :second)
      initial_rates = %{"NZD:USD" => %{rate: rate, time_updated: time_updated}}

      initial_state = %{
        rates: initial_rates,
        rates_api_module: RatesApi.Mock,
        tick_rate: 100
      }

      opts = [
        name: test,
        initial_state: initial_state
      ]

      assert {:ok, pid} = start_supervised({RatesServer, opts})

      Process.send(pid, :tick, [])

      assert state = RatesServer.get_state(test)
      assert rate == get_rate_param(state.rates, "NZD:USD", :rate)
      assert time_updated == get_rate_param(state.rates, "NZD:USD", :time_updated)
    end
  end

  defp get_rate_param(rates, code, param) do
    rates |> Map.get(code) |> Map.get(param)
  end
end
