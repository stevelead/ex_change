defmodule ExChangeWeb.Types.ExchangeRate do
  use Absinthe.Schema.Notation

  @desc "An exhange rate with a currency and rate"
  object :exchange_rate do
    field :currency, :string
    field :code, :string
    field :rate, :decimal
  end
end
