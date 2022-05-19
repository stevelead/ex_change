defmodule ExChange.AccountsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `ExChange.Accounts` context.
  """

  @doc """
  Generate a user.
  """
  def user_fixture(attrs \\ %{}) do
    {:ok, user} =
      attrs
      |> Enum.into(%{
        email: "some email"
      })
      |> ExChange.Accounts.create_user()

    user
  end
end
