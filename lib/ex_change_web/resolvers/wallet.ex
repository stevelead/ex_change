defmodule ExChangeWeb.Resolvers.Wallet do
  alias ExChange.Wallets

  def get_wallets_by_user_id(_parent, %{user_id: user_id}, _resolution) do
    {:ok, Wallets.list_wallets_by_user_id(user_id)}
  end
end
