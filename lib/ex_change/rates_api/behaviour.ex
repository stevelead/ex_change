defmodule ExChange.RatesApi.Behaviour do
  @type from_currency :: String.t()
  @type to_currency :: String.t()
  @type rate :: term()

  @callback fetch_rates(from_currency(), to_currency()) :: rate()
end
