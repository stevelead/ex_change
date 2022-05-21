defmodule ExChange.Wallets.Wallet do
  use Ecto.Schema
  import Ecto.Changeset

  alias ExChange.Accounts.User

  schema "wallets" do
    field :currency, :string
    field :balance, :decimal

    belongs_to :user, User

    timestamps()
  end

  @doc false
  def changeset(wallet, attrs) do
    wallet
    |> cast(attrs, [:currency, :balance, :user_id])
    |> validate_required([:currency])
  end
end
