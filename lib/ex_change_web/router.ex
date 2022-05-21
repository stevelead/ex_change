defmodule ExChangeWeb.Router do
  use ExChangeWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/api" do
    pipe_through :api

    forward "/", Absinthe.Plug, schema: ExChangeWeb.Schema
  end

  if Mix.env() == :dev do
    forward "/graphiql", Absinthe.Plug.GraphiQL,
      interface: :playground,
      schema: ExChangeWeb.Schema,
      socket: ExChangeWeb.UserSocket
  end
end
