defmodule ExChangeWeb.Schema.Subscriptions.ExchangeRate do
  use Absinthe.Schema.Notation

  object :exchange_rate_subscriptions do
    field :rate_updated, :exchange_rate do
      arg :currency, non_null(:string)

      config fn args, _ ->
        {:ok, topic: args.currency}
      end

      trigger :exchange_rate_update,
        topic: fn
          exchange_rate ->
            exchange_rate.currency
        end
    end
  end
end
