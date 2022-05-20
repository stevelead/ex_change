defmodule ExChangeWeb.Schema.Mutations.User do
  use Absinthe.Schema.Notation

  alias ExChangeWeb.Resolvers

  object :user_mutations do
    @desc "Creates a user"
    field :create_user, :user do
      arg :email, non_null(:string)

      resolve &Resolvers.User.create_user/3
    end
  end
end
