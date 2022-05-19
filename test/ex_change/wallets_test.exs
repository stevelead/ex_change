defmodule ExChange.WalletsTest do
  use ExChange.DataCase

  alias ExChange.Wallets

  describe "wallets" do
    alias ExChange.Wallets.Wallet

    import ExChange.WalletsFixtures
    import ExChange.AccountsFixtures

    @invalid_attrs %{currency: nil, value: nil}

    test "list_wallets/0 returns all wallets" do
      wallet = wallet_fixture()
      assert Wallets.list_wallets() == [wallet]
    end

    test "list_wallets_by_user_id/1 returns all users wallets" do
      user = user_fixture()
      wallet1 = wallet_fixture(user_id: user.id, currency: "USD")
      wallet2 = wallet_fixture(user_id: user.id, currency: "NZD")

      assert wallets_resp = Wallets.list_wallets_by_user_id(user.id)

      assert wallet_ids = wallets_resp |> Enum.map(& &1.id)
      assert Enum.any?(wallet_ids, &(&1 === wallet1.id))
      assert Enum.any?(wallet_ids, &(&1 === wallet2.id))
    end

    test "get_wallet!/1 returns the wallet with given id" do
      wallet = wallet_fixture()
      assert Wallets.get_wallet!(wallet.id) == wallet
    end

    test "create_wallet/1 with valid data creates a wallet" do
      valid_attrs = %{currency: "some currency", value: "120.5"}

      assert {:ok, %Wallet{} = wallet} = Wallets.create_wallet(valid_attrs)
      assert wallet.currency == "some currency"
      assert wallet.value == Decimal.new("120.5")
    end

    test "create_wallet/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Wallets.create_wallet(@invalid_attrs)
    end

    test "update_wallet/2 with valid data updates the wallet" do
      wallet = wallet_fixture()
      update_attrs = %{currency: "some updated currency", value: "456.7"}

      assert {:ok, %Wallet{} = wallet} = Wallets.update_wallet(wallet, update_attrs)
      assert wallet.currency == "some updated currency"
      assert wallet.value == Decimal.new("456.7")
    end

    test "update_wallet/2 with invalid data returns error changeset" do
      wallet = wallet_fixture()
      assert {:error, %Ecto.Changeset{}} = Wallets.update_wallet(wallet, @invalid_attrs)
      assert wallet == Wallets.get_wallet!(wallet.id)
    end

    test "delete_wallet/1 deletes the wallet" do
      wallet = wallet_fixture()
      assert {:ok, %Wallet{}} = Wallets.delete_wallet(wallet)
      assert_raise Ecto.NoResultsError, fn -> Wallets.get_wallet!(wallet.id) end
    end

    test "change_wallet/1 returns a wallet changeset" do
      wallet = wallet_fixture()
      assert %Ecto.Changeset{} = Wallets.change_wallet(wallet)
    end
  end
end
