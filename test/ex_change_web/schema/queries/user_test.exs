defmodule ExChangeWeb.Schema.Queries.UserTest do
  use ExChange.DataCase

  alias ExChangeWeb.Schema
  alias ExChange.RatesServer

  import ExChange.AccountsFixtures
  import ExChange.WalletsFixtures

  @user_doc """
    query User($id: ID!) {
    user(id: $id) {
      id
      email
      wallets {
        id
        currency
        value
      }
    }
  }
  """

  describe "@user" do
    test "fetches a user by id" do
      assert user = user_fixture()
      assert wallet = wallet_fixture(%{user_id: user.id})

      assert {:ok, %{data: data}} = Absinthe.run(@user_doc, Schema, variables: %{"id" => user.id})

      assert user_resp = data["user"]
      assert wallet.id == user_resp["wallets"] |> List.first() |> Map.get("id")
    end

    test "fetches a user by id with multiple wallets" do
      assert user = user_fixture()
      assert wallet1 = wallet_fixture(%{user_id: user.id})
      assert wallet2 = wallet_fixture(%{user_id: user.id, currency: "USD"})

      assert {:ok, %{data: data}} = Absinthe.run(@user_doc, Schema, variables: %{"id" => user.id})

      assert user_resp = data["user"]
      assert wallet_ids = user_resp["wallets"] |> Enum.map(& &1["id"])
      assert Enum.any?(wallet_ids, &(&1 === wallet1.id))
      assert Enum.any?(wallet_ids, &(&1 === wallet2.id))
    end
  end
end
