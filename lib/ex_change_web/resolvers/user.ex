defmodule ExChangeWeb.Resolvers.User do
  alias ExChange.Accounts

  def find_user(_parent, params, _resolution) do
    Accounts.find_user(params)
  end

  def create_user(_parent, params, _resolution) do
    Accounts.create_user(params)
  end
end
