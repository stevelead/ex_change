defmodule ExChangeWeb.Schema.Mutations.Wallet do
  use Absinthe.Schema.Notation

  alias ExChangeWeb.Resolvers

  object :wallet_mutations do
    @desc "Creates a wallet"
    field :create_wallet, :wallet do
      arg :user_id, non_null(:id)
      arg :currency, non_null(:string)

      resolve &Resolvers.Wallet.create_wallet/3
    end
  end
end
