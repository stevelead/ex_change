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

      now = DateTime.utc_now()

      initial_state = %{
        rates: %{
          "NZD:USD" => %{rate: Decimal.new("0.7"), last_update: now},
          "CAD:USD" => %{rate: Decimal.new("0.9"), last_update: now}
        },
        rates_api_module: RatesApi.Mock
      }

      assert {:ok, _pid} =
               start_supervised({RatesServer, [name: test, initial_state: initial_state]})

      assert {:ok, response} =
               Wallets.get_users_total_worth(Integer.to_string(user.id), "USD", test)

      assert "1.6" == response.total_worth
      assert "USD" == response.currency
      assert user.id == response.user_id
    end

    test "get_wallet!/1 returns the wallet with given id" do
      wallet = wallet_fixture()
      assert Wallets.get_wallet!(wallet.id) == wallet
    end

    test "find_wallet/1 returns the wallet with given params" do
      user = user_fixture()
      currency = "NZD"
      wallet = wallet_fixture(%{user_id: user.id, currency: currency})
      assert {:ok, ^wallet} = Wallets.find_wallet(%{user_id: user.id, currency: currency})
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

    test "send_payment/5 makes a payment when valid params", %{test: server_name} do
      initial_state = %{
        rates: %{"NZD:USD" => %{rate: Decimal.new("0.65"), last_update: DateTime.utc_now()}},
        rates_api_module: RatesApi.Mock
      }

      assert {:ok, _pid} =
               start_supervised({RatesServer, [name: server_name, initial_state: initial_state]})

      assert send_user = user_fixture(%{email: "some@real.email"})

      assert send_wallet =
               wallet_fixture(%{user_id: send_user.id, currency: "NZD", value: Decimal.new("5")})

      assert rec_user = user_fixture(%{email: "some@other.email"})

      assert rec_wallet =
               wallet_fixture(%{user_id: rec_user.id, currency: "USD", value: Decimal.new(0)})

      send_value = Decimal.new("5")

      assert {:ok, response} =
               Wallets.send_payment(
                 send_user.id,
                 rec_user.id,
                 send_wallet.currency,
                 send_value,
                 rec_wallet.currency,
                 server_name
               )

      assert response.sender_id == Integer.to_string(send_user.id)
      assert response.receiver_id == Integer.to_string(rec_user.id)

      assert {:ok, new_send_wallet} =
               Wallets.find_wallet(%{user_id: send_user.id, currency: send_wallet.currency})

      assert new_send_wallet.value == Decimal.new(0)

      assert {:ok, new_rec_wallet} =
               Wallets.find_wallet(%{user_id: rec_user.id, currency: rec_wallet.currency})

      assert new_rec_wallet.value == Decimal.new("3.25")
    end

    test "send_payment/5 returns an error when insufficient balance" do
      assert send_user = user_fixture(%{email: "some@real.email"})

      sender_wallet_balace = Decimal.new("4")
      incorrect_send_value = Decimal.new("5")

      assert send_wallet =
               wallet_fixture(%{
                 user_id: send_user.id,
                 currency: "NZD",
                 value: sender_wallet_balace
               })

      assert rec_user = user_fixture(%{email: "some@other.email"})

      assert rec_wallet =
               wallet_fixture(%{user_id: rec_user.id, currency: "USD", value: Decimal.new(0)})

      assert {:error, :insufficient_send_wallet_balance} =
               Wallets.send_payment(
                 send_user.id,
                 rec_user.id,
                 send_wallet.currency,
                 incorrect_send_value,
                 rec_wallet.currency
               )
    end

    test "send_payment/5 returns an error when incorrect send currency" do
      assert send_user = user_fixture(%{email: "some@real.email"})

      send_user_wallet_currency = "NZD"
      incorrect_currency = "AUS"

      assert _send_wallet =
               wallet_fixture(%{
                 user_id: send_user.id,
                 currency: send_user_wallet_currency,
                 value: Decimal.new("5")
               })

      assert rec_user = user_fixture(%{email: "some@other.email"})

      assert rec_wallet =
               wallet_fixture(%{user_id: rec_user.id, currency: "USD", value: Decimal.new(0)})

      send_value = Decimal.new("5")

      assert {:error, "send wallet for AUS currency not found"} =
               Wallets.send_payment(
                 send_user.id,
                 rec_user.id,
                 incorrect_currency,
                 send_value,
                 rec_wallet.currency
               )
    end

    test "send_payment/5 returns an error when incorrect receiver currency" do
      assert send_user = user_fixture(%{email: "some@real.email"})

      assert send_wallet =
               wallet_fixture(%{user_id: send_user.id, currency: "NZD", value: Decimal.new("5")})

      assert rec_user = user_fixture(%{email: "some@other.email"})

      rec_user_wallet_currency = "USD"
      incorrect_currency = "AUS"

      assert _rec_wallet =
               wallet_fixture(%{
                 user_id: rec_user.id,
                 currency: rec_user_wallet_currency,
                 value: Decimal.new(0)
               })

      send_value = Decimal.new("5")

      assert {:error, "rec wallet for AUS currency not found"} =
               Wallets.send_payment(
                 send_user.id,
                 rec_user.id,
                 send_wallet.currency,
                 send_value,
                 incorrect_currency
               )
    end
  end
end
