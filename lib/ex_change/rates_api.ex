defmodule ExChange.RatesApi do
  alias ExChange.RatesApi.Rate

  def fetch_rates(from, to) when is_binary(from) and is_binary(to) do
    with fetch_time <- DateTime.utc_now(),
         code <- "#{from}:#{to}" do
      make_request(from, to, fetch_time, code)
    end
  end

  def fetch_rates(_from, _to), do: {:error, "both params must be binaries"}

  defp make_request(from, to, fetch_time, code) do
    with res <- Req.get!(make_url(from, to)),
         {:status, 200} <- {:status, res.status},
         %{"Realtime Currency Exchange Rate" => rate_details} <- res.body,
         rate <- Map.get(rate_details, "5. Exchange Rate") do
      case rate do
        nil ->
          {:error, "nil value received from rates api for #{code} at #{fetch_time}"}

        rate when is_binary(rate) ->
          Rate.new(code, rate, fetch_time)

        value ->
          {:error, "#{value} received from rates api for #{code} at #{fetch_time}"}
      end
    else
      {:status, status} ->
        {:error, "#{status} status received from rates api for #{code} at #{fetch_time}"}

      %{
        "Error Message" => error
      } ->
        {:error, "#{error}: message received from rates api for #{code} at #{fetch_time}"}
    end
  end

  defp make_url(from, to) do
    api_url() <>
      "/query?function=CURRENCY_EXCHANGE_RATE&from_currency=#{from}&to_currency=#{to}&apikey=#{api_key()}"
  end

  defp api_url() do
    Application.get_env(:ex_change, :alphavantage_api_url) || "http://localhost:4001"
  end

  defp api_key() do
    Application.get_env(:ex_change, :alphavantage_api_key)
  end
end
