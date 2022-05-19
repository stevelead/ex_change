defmodule ExChangeWeb.Resolvers.User do
  alias ExChange.Accounts

  def get_user(_parent, params, _resolution) do
    Accounts.get_user(params)
  end
end