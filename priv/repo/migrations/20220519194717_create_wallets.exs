defmodule ExChange.Repo.Migrations.CreateWallets do
  use Ecto.Migration

  def change do
    create table(:wallets) do
      add :currency, :string
      add :value, :decimal
      add :user, references(:users, on_delete: :nothing)

      timestamps()
    end

    create index(:wallets, [:user])
  end
end
