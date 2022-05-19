defmodule ExChange.Rates.RatesApiMock do
  @behaviour ExChange.Rates.RatesApiBehaviour
  require Logger

  def fetch(from, to) do
    Logger.info("@rates_api_module fetch/2 called with params [#{from}, #{to}]")

    response =
      case {from, to} do
        {"NZD", "USD"} ->
          "0.65"

        _ ->
          generate_float_as_string()
      end

    Logger.info("Response value #{response}")
    response
  end

  def generate_float_as_string() do
    StreamData.float(min: 0.000001, max: 9.99999)
    |> Enum.take(1)
    |> List.first()
    |> Float.to_string()
  end
end
