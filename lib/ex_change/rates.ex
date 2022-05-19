defmodule ExChange.Rates do
  use GenServer
  require Logger

  alias ExChange.Rates
  alias ExChange.Rates.RatesApi

  @default_name ExChange.Rates
  @default_tick_rate :timer.seconds(1)

  defstruct rates: %{},
            wallet_currency_count: %{},
            rates_api_module: RatesApi,
            tick_rate: @default_tick_rate

  # API

  def start_link(opts \\ []) do
    initial_state = Keyword.get(opts, :initial_state, %{})
    state = struct!(%Rates{}, initial_state)

    name = Keyword.get(opts, :name, @default_name)

    GenServer.start_link(__MODULE__, state, name: via_tuple(name))
  end

  def state(server \\ @default_name) do
    GenServer.call(via_tuple(server), :state)
  end

  def via_tuple(name) when is_atom(name) or is_binary(name) do
    {:via, Registry, {ExChange.Registry, name}}
  end

  # Server

  @impl true
  def init(state) do
    :timer.send_interval(state.tick_rate, self(), :tick)

    {:ok, state}
  end

  @impl true
  def handle_call(:state, _from, state) do
    {:reply, state, state}
  end

  @impl true
  def handle_info(:tick, state) do
    updated_rates =
      fetch_exchange_rates(state)
      |> Enum.reduce(state.rates, &update_rates/2)

    {:noreply, %{state | rates: updated_rates}}
  end

  def fetch_exchange_rates(state) do
    all_codes = get_combinations(state)

    Task.async_stream(all_codes, fn {from, to} ->
      state.rates_api_module.fetch(from, to)
    end)
    |> Enum.reduce([], fn
      {:ok, response}, acc ->
        [response | acc]

      {:error, error}, acc ->
        Logger.warn(error)
        acc
    end)
  end

  def get_combinations(state) do
    held_currencies = Map.keys(state.wallet_currency_count)

    for from <- held_currencies, to <- held_currencies, from !== to do
      {from, to}
    end
  end

  def update_rates(rate, acc) do
    if current = Map.get(acc, rate.code) do
      put_most_recent(rate, current, acc)
    else
      put_new_rate(rate, acc)
    end
  end

  def put_most_recent(new_rate, current_rate, acc) do
    get_most_recent(new_rate, current_rate)
    |> put_new_rate(acc.rates)
  end

  def get_most_recent(new_rate, current_rate) do
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
