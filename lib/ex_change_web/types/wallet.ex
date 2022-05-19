defmodule ExChangeWeb.Types.Wallet do
  use Absinthe.Schema.Notation
  import Absinthe.Resolution.Helpers, only: [dataloader: 1]

  @desc "A wallet with an id, a currency, value and a user"
  object :wallet do
    field :id, :integer
    field :currency, :string
    field :value, :decimal

    field :user, :user, resolve: dataloader(ExChange.Accounts)
  end
end
