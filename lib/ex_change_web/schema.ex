defmodule ExChangeWeb.Schema do
  use Absinthe.Schema

  import_types ExChangeWeb.Types.User
  import_types ExChangeWeb.Types.Wallet
  import_types ExChangeWeb.Types.ExchangeRate
  import_types Absinthe.Type.Custom

  import_types ExChangeWeb.Schema.Queries.User
  import_types ExChangeWeb.Schema.Queries.Wallet

  import_types ExChangeWeb.Schema.Mutations.User
  import_types ExChangeWeb.Schema.Mutations.Wallet

  import_types ExChangeWeb.Schema.Subscriptions.Wallet
  import_types ExChangeWeb.Schema.Subscriptions.ExchangeRate

  query do
    import_fields :user_queries
    import_fields :wallet_queries
  end

  mutation do
    import_fields :user_mutations
    import_fields :wallet_mutations
  end

  subscription do
    import_fields :wallet_subscriptions
    import_fields :exchange_rate_subscriptions
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
