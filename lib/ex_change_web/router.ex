defmodule ExChangeWeb.Router do
  use ExChangeWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/" do
    pipe_through :api

    forward "/api", Absinthe.Plug, schema: ExChangeWeb.Schema
  end

  if Mix.env() == :dev do
    forward "/graphiql",
            Absinthe.Plug.GraphiQL,
            schema: ExChangeWeb.Schema,
            interface: :playground,
            socket: ExChangeWeb.UserSocket
  end
end
