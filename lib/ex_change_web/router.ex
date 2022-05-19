defmodule ExChangeWeb.Router do
  use ExChangeWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/api", ExChangeWeb do
    pipe_through :api
  end
end
