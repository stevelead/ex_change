defmodule ExChangeWeb.Schema do
  use Absinthe.Schema

  import_types ExChangeWeb.Types.User
  import_types ExChangeWeb.Types.Wallet
  import_types Absinthe.Type.Custom

  import_types ExChangeWeb.Schema.Queries.User

  query do
    import_fields(:user_queries)
  end

  def context(ctx) do
    source = Dataloader.Ecto.new(ExChange.Repo)

    dataloader =
      Dataloader.new()
      |> Dataloader.add_source(ExChange.Accounts, source)
      |> Dataloader.add_source(ExChange.Wallets, source)

    Map.put(ctx, :loader, dataloader)
  end

  def plugins do
    [Absinthe.Middleware.Dataloader] ++ Absinthe.Plugin.defaults()
  end
end