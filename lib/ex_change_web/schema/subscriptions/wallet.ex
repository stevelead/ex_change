defmodule ExChangeWeb.Schema.Subscriptions.Wallet do
  use Absinthe.Schema.Notation

  alias ExChange.Wallets

  object :wallet_subscriptions do
    field :total_worth_changed, :total_worth do
      arg :user_id, non_null(:id)

      config fn args, _ ->
        topic = "total_worth_changed:" <> args.user_id
        {:ok, topic: topic}
      end

      trigger :total_worth_change,
        topic: fn
          %{sender_id: sender_id, receiver_id: receiver_id} ->
            for id <- [sender_id, receiver_id] do
              "total_worth_changed:" <> "#{id}"
            end
        end

      resolve fn
        %{sender_id: sender_id, send_currency: currency, api_server: api_server},
        %{user_id: sender_id},
        _ ->
          with {:ok, total_worth} <-
                 Wallets.get_users_total_worth(sender_id, currency, api_server) do
            {:ok, total_worth}
          end

        %{receiver_id: receiver_id, receive_currency: currency, api_server: api_server},
        %{user_id: receiver_id},
        _ ->
          with {:ok, total_worth} <-
                 Wallets.get_users_total_worth(receiver_id, currency, api_server) do
            {:ok, total_worth}
          end
      end
    end
  end
end
