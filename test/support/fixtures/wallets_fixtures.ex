defmodule ExChange.WalletsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `ExChange.Wallets` context.
  """

  @doc """
  Generate a wallet.
  """
  def wallet_fixture(attrs \\ %{}) do
    {:ok, wallet} =
      attrs
      |> Enum.into(%{
        currency: "NZD",
        value: "120.5"
      })
      |> ExChange.Wallets.create_wallet()

    wallet
  end
end
