defmodule ExChange.RatesServer.Helpers do
  require Logger

  def handle_responses(responses, state) do
    responses
    |> Enum.reduce([], fn
      {:ok, response}, acc ->
        [response | acc]

      {:error, error}, acc ->
        Logger.warn(error)
        acc
    end)
    |> Enum.reduce(state.rates, &update_rates/2)
  end

  defp update_rates(rate, acc) do
    if current = Map.get(acc, rate.code) do
      put_most_recent(rate, current, acc)
    else
      put_new_rate(rate, acc)
    end
  end

  defp put_most_recent(new_rate, current_rate, acc) do
    get_most_recent(new_rate, current_rate)
    |> put_new_rate(acc.rates)
  end

  defp get_most_recent(new_rate, current_rate) do
    case DateTime.compare(new_rate, current_rate) do
      :gt -> new_rate
      :lt -> current_rate
    end
  end

  def put_new_rate(new_rate, rates) do
    {code, rest} = Map.pop!(new_rate, :code)
    Map.put(rates, code, rest)
  end
end
