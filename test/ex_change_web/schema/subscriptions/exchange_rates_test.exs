defmodule ExChangeWeb.Schema.Subscriptions.ExchangeRatesTest do
  use ExChangeWeb.SubscriptionCase

  alias ExChange.RatesServer

  import ExChange.AccountsFixtures

  @rate_updated_sub_doc """
  subscription RateUpdated($currency: String!) {
    rateUpdated(currency: $currency) {
      currency
      rate
    }
  }
  """

  describe "@rateUpdated" do
    test "subscribe to rate updates", %{socket: socket, test: server_name} do
      initial_rate = Decimal.new("0.55")

      initial_state = %{
        rates: %{"NZD:USD" => %{rate: initial_rate, last_updated: DateTime.utc_now()}},
        rates_api_module: RatesApi.Mock
      }

      assert {:ok, pid} =
               start_supervised({RatesServer, [name: server_name, initial_state: initial_state]})

      variables = %{"currency" => "NZD"}
      ref = push_doc(socket, @rate_updated_sub_doc, variables: variables)

      assert_reply ref, :ok, %{subscriptionId: subscription_id}

      assert Process.send(pid, :tick, [])

      assert_push "subscription:data", data

      assert %{
               subscriptionId: ^subscription_id,
               result: %{
                 data: %{
                   "rateUpdated" => rate_updated_data
                 }
               }
             } = data

      assert rate_updated_data["currency"] == variables["currency"]
      assert rate_updated_data["rate"] !== initial_rate
    end
  end
end
