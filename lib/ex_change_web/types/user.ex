defmodule ExChangeWeb.Types.User do
  use Absinthe.Schema.Notation
  import Absinthe.Resolution.Helpers, only: [dataloader: 1]

  @desc "A user with an id, an email and wallets"
  object :user do
    field :id, :integer
    field :email, :string

    field :wallets, list_of(:wallet), resolve: dataloader(ExChange.Wallets)
  end
end
