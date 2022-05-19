defmodule ExChangeWeb.Schema.Queries.Wallet do
  use Absinthe.Schema.Notation
  alias ExChangeWeb.Resolvers

  object :wallet_queries do
    @desc "A list of wallets by user_id"
    field :wallets, list_of(:wallet) do
      arg :user_id, non_null(:id)

      resolve(&Resolvers.Wallet.get_wallets_by_user_id/3)
    end
  end
end
