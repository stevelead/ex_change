defmodule ExChangeWeb.Resolvers.Wallet do
  alias ExChange.Wallets

  def get_wallets_by_user_id(_parent, %{user_id: user_id}, _resolution) do
    {:ok, Wallets.list_wallets_by_user_id(user_id)}
  end

  def find_wallet(_parent, params, _resolution) do
    Wallets.find_wallet(params)
  end

  def create_wallet(_parent, params, _resolution) do
    Wallets.create_wallet(params)
  end

  def get_users_total_worth(_parent, %{user_id: user_id, currency: currency}, _resolution) do
    Wallets.get_users_total_worth(user_id, currency)
  end
end
