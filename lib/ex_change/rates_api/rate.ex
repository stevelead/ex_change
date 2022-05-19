defmodule ExChange.RatesApi.Rate do
  defstruct code: nil, rate: nil, last_update: nil

  alias ExChange.RatesApi.Rate

  def new(code, rate, time \\ now())

  def new(code, rate, time) when is_binary(rate) do
    decimal_rate = Decimal.new(rate)
    %Rate{code: code, rate: decimal_rate, last_update: time}
  end

  defp now() do
    DateTime.utc_now()
  end
end
