defmodule ExChangeWeb.Schema.Queries.WalletTest do
  use ExChange.DataCase

  alias ExChange.RatesServer
  alias ExChange.RatesApi
  alias ExChange.RatesApi.Rate

  import ExChange.AccountsFixtures
  import ExChange.WalletsFixtures
  alias ExChangeWeb.Schema

  @wallets_doc """
    query Wallets($user_id: ID!) {
    wallets(user_id: $user_id) {
      id
      currency
      balance
      user {
        id
        email
      }
    }
  }
  """

  describe "@wallets" do
    test "fetches wallets by user_id" do
      assert user = user_fixture()
      assert wallet = wallet_fixture(%{user_id: user.id})

      assert {:ok, %{data: data}} =
               Absinthe.run(@wallets_doc, Schema, variables: %{"user_id" => user.id})

      assert wallets_resp = data["wallets"]
      assert wallet.id == wallets_resp |> List.first() |> Map.get("id")
      assert user.id == get_first_user_id(wallets_resp)
    end

    test "fetches multiple wallets by user_id" do
      assert user = user_fixture()
      assert wallet1 = wallet_fixture(%{user_id: user.id})
      assert wallet2 = wallet_fixture(%{user_id: user.id, currency: "USD"})

      assert {:ok, %{data: data}} =
               Absinthe.run(@wallets_doc, Schema, variables: %{"user_id" => user.id})

      assert wallets_resp = data["wallets"]

      assert wallet_ids = wallets_resp |> Enum.map(& &1["id"])

      for %{id: id} <- [wallet1, wallet2] do
        assert Enum.any?(wallet_ids, &(&1 === id))
      end

      assert user.id == get_first_user_id(wallets_resp)
    end
  end

  @wallet_by_currency_doc """
    query WalletsByCurrency($user_id: ID!, $currency: String!) {
    walletByCurrency(user_id: $user_id, currency: $currency) {
      id
      currency
      balance
      user {
        id
        email
      }
    }
  }
  """

  describe "@walletByCurrency" do
    test "fetches wallet by user_id and currency" do
      currency = "NZD"
      assert user = user_fixture()
      assert wallet = wallet_fixture(%{user_id: user.id, currency: currency})

      assert {:ok, %{data: data}} =
               Absinthe.run(@wallet_by_currency_doc, Schema,
                 variables: %{"user_id" => user.id, "currency" => currency}
               )

      assert wallet_resp = data["walletByCurrency"]
      assert wallet.id == wallet_resp["id"]
      assert currency == wallet_resp["currency"]
      assert user.id == get_in(wallet_resp, ["user", "id"])
    end
  end

  @total_worth_doc """
    query TotalWorth($user_id: ID!, $currency: String!) {
    totalWorth(user_id: $user_id, currency: $currency) {
      user_id
      currency
      total_worth
    }
  }
  """

  @tag :external
  describe "Integration test - @totalWorth" do
    test "fetches the total worth of a user" do
      assert user = user_fixture()

      wallet_currencies = [{"NZD", 10}, {"USD", 100}, {"CAD", 1000}]

      for {currency, balance} <- wallet_currencies do
        wallet_fixture(%{user_id: user.id, currency: currency, balance: balance})
      end

      rates =
        [{"NZD:USD", "0.65"}, {"CAD:USD", "0.95"}]
        |> into_rates_map()

      initial_state = %{rates: rates, rates_api_module: RatesApi}

      assert {:ok, _pid} = start_supervised({RatesServer, [initial_state: initial_state]})

      assert {:ok, %{data: data}} =
               Absinthe.run(@total_worth_doc, Schema,
                 variables: %{"user_id" => user.id, "currency" => "USD"}
               )

      assert total_worth_resp = data["totalWorth"]
      assert user.id == total_worth_resp["user_id"]
      assert "USD" == total_worth_resp["currency"]
      assert "1056.50" == total_worth_resp["total_worth"]
    end
  end

  defp get_first_user_id(resp) do
    resp |> List.first() |> get_in(["user", "id"])
  end

  defp into_rates_map(rates_list) do
    rates_list
    |> Enum.map(fn {code, rate} -> Rate.new(code, rate) end)
    |> Enum.reduce(%{}, &RatesServer.Helpers.update_rates/2)
  end
end
