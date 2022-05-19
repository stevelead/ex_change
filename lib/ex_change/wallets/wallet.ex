defmodule ExChange.Wallets.Wallet do
  use Ecto.Schema
  import Ecto.Changeset

  schema "wallets" do
    field :currency, :string
    field :value, :decimal
    field :user, :id

    timestamps()
  end

  @doc false
  def changeset(wallet, attrs) do
    wallet
    |> cast(attrs, [:currency, :value])
    |> validate_required([:currency, :value])
  end
end
