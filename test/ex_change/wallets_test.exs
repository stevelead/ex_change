defmodule ExChange.WalletsTest do
  use ExChange.DataCase

  alias ExChange.Wallets

  describe "wallets" do
    alias ExChange.Wallets.Wallet
    alias ExChange.RatesServer

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

    test "get_users_total_worth/2 returns user's total worth", %{test: test} do
      user = user_fixture()

      for currency <- ["NZD", "CAD"] do
        wallet_fixture(user_id: user.id, currency: currency, value: 1)
      end

      initial_state = %{
        rates: %{"NZD:USD" => %{rate: "0.7"}, "CAD:USD" => %{rate: "0.9"}},
        rates_api_module: RatesApi.Mock
      }

      assert {:ok, _pid} =
               start_supervised({RatesServer, [name: test, initial_state: initial_state]})

      assert response = Wallets.get_users_total_worth(Integer.to_string(user.id), "USD", test)
      assert "1.6" == response.total_worth
      assert "USD" == response.currency
      assert user.id == response.user_id
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

    test "get_currency_count/1 returns a map with total currency counts" do
      wallets =
        for currency <- ["NZD", "NZD", "USD"] do
          wallet_fixture(%{currency: currency})
        end

      assert %{"NZD" => 2, "USD" => 1} = Wallets.get_currency_count(wallets)
    end

    test "add_currency/2 returns a map with total currency counts" do
      wallets =
        for currency <- ["NZD", "NZD", "USD"] do
          wallet_fixture(%{currency: currency})
        end

      assert initial_currency_count = Wallets.get_currency_count(wallets)
      assert additional_wallet = wallet_fixture(%{currency: "USD"})

      assert %{"NZD" => 2, "USD" => 2} =
               Wallets.add_currency(additional_wallet, initial_currency_count)
    end

    test "get_exchange_combinations/1 returns a list of exchange cobinations" do
      wallets =
        for currency <- ["NZD", "NZD", "USD"] do
          wallet_fixture(%{currency: currency})
        end

      assert currency_count = Wallets.get_currency_count(wallets)

      assert [{"NZD", "USD"}, {"USD", "NZD"}] = Wallets.get_exchange_combinations(currency_count)
    end
  end
end
