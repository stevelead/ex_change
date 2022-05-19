defmodule ExChange.Rates.RatesApiMock do
  @behaviour ExChange.Rates.RatesApiBehaviour
  require Logger

  alias ExChange.Rates.Rate

  def fetch(from, to) do
    fetch_time = DateTime.utc_now()

    code = "#{from}:#{to}"

    rate =
      case {from, to} do
        {"NZD", "USD"} ->
          "0.65"

        _ ->
          generate_float_as_string()
      end

    Rate.new(code, rate, fetch_time)
  end

  def generate_float_as_string() do
    StreamData.float(min: 0.000001, max: 9.99999)
    |> Enum.take(1)
    |> List.first()
    |> Float.to_string()
  end
end
