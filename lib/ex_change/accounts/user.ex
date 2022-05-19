defmodule ExChange.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset

  alias ExChange.Wallets.Wallet

  schema "users" do
    field :email, :string

    has_many :wallets, Wallet

    timestamps()
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:email])
    |> validate_required([:email])
  end
end
