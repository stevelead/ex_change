defmodule ExChangeWeb.Schema.Mutations.WalletTest do
  use ExChange.DataCase, async: true

  alias ExChangeWeb.Schema
  alias ExChange
  import ExChange.AccountsFixtures

  @create_wallet """
    mutation CreateWallet($user_id: ID!, $currency: String!) {
    createWallet(user_id: $user_id, currency: $currency) {
      id
      currency
      value
      user {
        id
        email
        wallets {
          id
          currency
          value
        }
      }
    }
  }
  """

  describe "@createWallet" do
    test "creates a wallet" do
      assert user = user_fixture()

      wallet_params = %{
        "user_id" => user.id,
        "currency" => "NZD"
      }

      assert {:ok, %{data: data}} = Absinthe.run(@create_wallet, Schema, variables: wallet_params)

      wallet_res = data["createWallet"]
      assert wallet_params["currency"] === wallet_res["currency"]

      assert {:ok, wallet} =
               ExChange.Wallets.find_wallet(%{email: wallet_params["email"], preload: :user})

      assert wallet.id === wallet_res["id"]
      assert wallet.currency === wallet_res["currency"]
      assert wallet.user.id === user.id
    end
  end
end