defmodule ExChangeWeb.Schema.Mutations.UserTest do
  use ExChange.DataCase, async: true

  alias ExChangeWeb.Schema

  alias ExChange

  @create_user """
    mutation CreateUser($email: String!) {
    createUser(email: $email) {
      id
      email
    }
  }
  """

  describe "@createUser" do
    test "creates a user" do
      user_params = %{
        "email" => "some@email.com"
      }

      assert {:ok, %{data: data}} = Absinthe.run(@create_user, Schema, variables: user_params)

      user_res = data["createUser"]
      assert user_res["email"] === user_params["email"]

      assert {:ok, account} = ExChange.Accounts.get_user(%{email: user_params["email"]})
      assert account.id === user_res["id"]
      assert account.email === user_res["email"]
      assert account.email === user_params["email"]
    end
  end
end
