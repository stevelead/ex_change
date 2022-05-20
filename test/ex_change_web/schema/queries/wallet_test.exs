defmodule ExChangeWeb.Schema.Queries.WalletTest do
  use ExChange.DataCase, async: true

  import ExChange.AccountsFixtures
  import ExChange.WalletsFixtures
  alias ExChangeWeb.Schema

  @wallets """
    query Wallets($user_id: ID!) {
    wallets(user_id: $user_id) {
      id
      currency
      value
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
               Absinthe.run(@wallets, Schema, variables: %{"user_id" => user.id})

      assert wallets_resp = data["wallets"]
      assert wallet.id == wallets_resp |> List.first() |> Map.get("id")
      assert user.id == get_first_user_id(wallets_resp)
    end

    test "fetches multiple wallets by user_id" do
      assert user = user_fixture()
      assert wallet1 = wallet_fixture(%{user_id: user.id})
      assert wallet2 = wallet_fixture(%{user_id: user.id, currency: "USD"})

      assert {:ok, %{data: data}} =
               Absinthe.run(@wallets, Schema, variables: %{"user_id" => user.id})

      assert wallets_resp = data["wallets"]

      assert wallet_ids = wallets_resp |> Enum.map(& &1["id"])

      for %{id: id} <- [wallet1, wallet2] do
        assert Enum.any?(wallet_ids, &(&1 === id))
      end

      assert user.id == get_first_user_id(wallets_resp)
    end
  end

  @wallet_by_currency """
    query WalletsByCurrency($user_id: ID!, $currency: String!) {
    walletByCurrency(user_id: $user_id, currency: $currency) {
      id
      currency
      value
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
               Absinthe.run(@wallet_by_currency, Schema,
                 variables: %{"user_id" => user.id, "currency" => currency}
               )

      assert wallet_resp = data["walletByCurrency"]
      assert wallet.id == wallet_resp["id"]
      assert currency == wallet_resp["currency"]
      assert user.id == get_in(wallet_resp, ["user", "id"])
    end
  end

  def get_first_user_id(resp) do
    resp |> List.first() |> get_in(["user", "id"])
  end
end
