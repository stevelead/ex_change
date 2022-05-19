defmodule ExChange.RatesApi.Behaviour do
  @type from_currency :: String.t()
  @type to_currency :: String.t()
  @type rate :: String.t()

  @callback fetch_rates(from_currency(), to_currency()) :: rate()
end
