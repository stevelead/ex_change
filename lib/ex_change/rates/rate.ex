defmodule ExChange.Rates.Rate do
  defstruct code: nil, rate: nil, last_update: nil

  alias ExChange.Rates.Rate

  def new(code, rate, time \\ now())

  def new(code, rate, time) when is_binary(rate) do
    decimal_rate = Decimal.new(rate)
    %Rate{code: code, rate: decimal_rate, last_update: time}
  end

  def new(code, rate, time) when is_float(rate) do
    decimal_rate = Decimal.from_float(rate)
    %Rate{code: code, rate: decimal_rate, last_update: time}
  end

  defp now() do
    DateTime.now!("Etc/UTC")
  end
end
