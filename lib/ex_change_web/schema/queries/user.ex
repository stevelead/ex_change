defmodule ExChangeWeb.Schema.Queries.User do
  use Absinthe.Schema.Notation
  alias ExChangeWeb.Resolvers

  object :user_queries do
    @desc "A user by id"
    field :user, :user do
      arg :id, non_null(:id)

      resolve(&Resolvers.User.find_user/3)
    end
  end
end
