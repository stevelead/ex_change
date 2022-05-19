defmodule ExChange.Repo.Migrations.CreateWallets do
  use Ecto.Migration

  def change do
    create table(:wallets) do
      add :currency, :string
      add :value, :decimal
      add :user_id, references(:users, on_delete: :nothing)

      timestamps()
    end

    create index(:wallets, [:user_id])
    create unique_index(:wallets, [:user_id, :currency])
  end
end
