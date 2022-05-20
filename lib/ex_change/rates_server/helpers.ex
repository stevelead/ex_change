defmodule ExChange.RatesServer.Helpers do
  alias ExChange.RatesApi.Rate

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

  # rates not in acc below as %{"NZD:USD" => etc}
  defp put_most_recent(new_rate, current_rate, acc) do
    get_most_recent(new_rate, current_rate)
    |> put_new_rate(acc)
  end

  defp get_most_recent(new_rate, current_rate) do
    case DateTime.compare(new_rate.last_update, current_rate.last_update) do
      :gt -> new_rate
      :lt -> current_rate
    end
  end

  def put_new_rate(new_rate, rates) do
    {code, rest} = Map.pop!(new_rate, :code)
    Map.put(rates, code, rest)
  end
end
