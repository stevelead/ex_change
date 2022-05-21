defmodule ExChangeWeb.Schema.Subscriptions.WalletTest do
  use ExChangeWeb.SubscriptionCase

  alias ExChange.Wallets
  alias ExChange.RatesServer

  import ExChange.AccountsFixtures
  import ExChange.WalletsFixtures

  @total_worth_sub_doc """
  subscription TotalWorthChanged($userId: ID!) {
    totalWorthChanged(userId: $userId) {
      user_id
      currency
      total_worth
    }
  }
  """

  describe "@totalWorthChanged" do
    test "subscribe to total worth changes", %{
      socket: socket,
      test: server_name
    } do
      initial_state = %{
        rates: %{"NZD:USD" => %{rate: Decimal.new("0.65"), last_updated: DateTime.utc_now()}},
        rates_api_module: RatesApi.Mock
      }

      assert {:ok, _pid} =
               start_supervised({RatesServer, [name: server_name, initial_state: initial_state]})

      [send_user, rec_user] =
        for email <- ["some@real.email", "some@other.email"] do
          user_fixture(%{email: email})
        end

      assert send_wallet =
               wallet_fixture(%{user_id: send_user.id, currency: "NZD", value: Decimal.new("5")})

      assert rec_wallet =
               wallet_fixture(%{user_id: rec_user.id, currency: "USD", value: Decimal.new(0)})

      send_value = Decimal.new("5")

      [send_ref, rec_ref] =
        for user <- [send_user, rec_user] do
          push_doc(socket, @total_worth_sub_doc, variables: %{"userId" => user.id})
        end

      [send_sub_id, rec_sub_id_2] =
        for ref <- [send_ref, rec_ref] do
          assert_reply ref, :ok, %{subscriptionId: subscription_id}
          subscription_id
        end

      send_user_id = send_user.id
      rec_user_id = rec_user.id

      assert {:ok, _response} =
               Wallets.send_payment(
                 send_user_id,
                 rec_user_id,
                 send_wallet.currency,
                 send_value,
                 rec_wallet.currency,
                 server_name
               )

      assert_push "subscription:data", data1
      assert_push "subscription:data", data2

      assert %{
               subscriptionId: ^send_sub_id,
               result: %{
                 data: %{
                   "totalWorthChanged" => %{
                     "currency" => "NZD",
                     "total_worth" => "0",
                     "user_id" => ^send_user_id
                   }
                 }
               }
             } = data1

      assert %{
               subscriptionId: ^rec_sub_id_2,
               result: %{
                 data: %{
                   "totalWorthChanged" => %{
                     "currency" => "USD",
                     "total_worth" => "3.25",
                     "user_id" => ^rec_user_id
                   }
                 }
               }
             } = data2
    end
  end
end
