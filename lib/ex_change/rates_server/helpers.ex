defmodule ExChange.RatesServer.Helpers do
  alias ExChange.RatesApi.Rate
  alias ExChangeWeb.Endpoint

  require Logger

  def handle_responses(responses, state) do
    responses
    |> Enum.reduce([], fn
      {:ok, {:error, error}}, acc ->
        Logger.warn(error)
        acc

      {:ok, %Rate{} = rate}, acc ->
        [rate | acc]

      {:error, error}, acc ->
        Logger.warn(error)
        acc
    end)
    |> Enum.reduce(state.rates, &update_rates/2)
  end

  def update_rates(rate, acc) do
    if current = Map.get(acc, rate.code) do
      put_most_recent(rate, current, acc)
    else
      put_new_rate(rate, acc)
    end
  end

  defp put_most_recent(new_rate, current_rate, acc) do
    new_rate
    |> get_most_recent(current_rate)
    |> publish_rate_update()
    |> put_new_rate(acc)
  end

  defp get_most_recent(new_rate, current_rate) do
    case DateTime.compare(new_rate.last_update, current_rate.last_update) do
      :gt -> new_rate
      :lt -> current_rate
    end
  end

  def publish_rate_update(rate) do
    rate.code
    |> get_currency()
    |> do_publish(rate)
  end

  defp get_currency(code) do
    code
    |> String.split(":")
    |> hd()
  end

  defp do_publish(currency, rate) do
    with :ok <-
           Absinthe.Subscription.publish(Endpoint, Map.put(rate, :currency, currency),
             rate_updated: currency
           ) do
      rate
    end
  end

  def put_new_rate(new_rate, rates) do
    {code, rest} = Map.pop!(new_rate, :code)
    Map.put(rates, code, rest)
  end
end
