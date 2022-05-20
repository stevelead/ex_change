defmodule ExChangeWeb.Types.Wallet do
  use Absinthe.Schema.Notation
  import Absinthe.Resolution.Helpers, only: [dataloader: 1]
  ExChangeWeb.Resolvers.Wallet

  @desc "A wallet with an id, a currency, value and a user"
  object :wallet do
    field :id, :integer
    field :currency, :string
    field :value, :decimal

    field :user, :user, resolve: dataloader(ExChange.Accounts)
  end

  @desc "The user id, currency and total worth of a user's wallets in the currency"
  object :total_worth do
    field :user_id, :integer
    field :currency, :string
    field :total_worth, :string
  end
end
