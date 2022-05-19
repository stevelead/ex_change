defmodule ExChangeWeb.Resolvers.Wallet do
  alias ExChange.Wallets

  def get_wallets_by_user_id(_parent, %{user_id: user_id}, _resolution) do
    {:ok, Wallets.list_wallets_by_user_id(user_id)}
  end

  def find_wallet(_parent, params, _resolution) do
    Wallets.find_wallet(params)
  end
end
