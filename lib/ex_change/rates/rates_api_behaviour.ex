defmodule ExChange.Rates.RatesApiBehaviour do
  @type from_currency :: String.t()
  @type to_currency :: String.t()
  @type rate :: String.t()

  @callback fetch(from_currency(), to_currency()) :: rate()
end
