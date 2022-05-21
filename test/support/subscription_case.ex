defmodule ExChangeWeb.SubscriptionCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      use ExChangeWeb.ChannelCase

      use Absinthe.Phoenix.SubscriptionTest,
        schema: ExChangeWeb.Schema

      alias ExChange.Repo

      setup do
        {:ok, socket} = Phoenix.ChannelTest.connect(ExChangeWeb.UserSocket, %{})
        {:ok, socket} = Absinthe.Phoenix.SubscriptionTest.join_absinthe(socket)

        {:ok, %{socket: socket}}
      end
    end
  end
end
