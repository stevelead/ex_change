defmodule ExChange.RatesServer do
  use GenServer
  require Logger

  alias ExChange.RatesServer
  alias ExChange.RatesServer.Helpers
  alias ExChange.RatesApi
  alias ExChange.Wallets

  @default_name ExChange.RatesServer
  @default_rates_api_module RatesApi
  @default_tick_rate :timer.seconds(1)

  defstruct rates: %{},
            currency_count: %{},
            rates_api_module: @default_rates_api_module,
            tick_rate: @default_tick_rate

  # API

  def start_link(opts \\ []) do
    initial_state = Keyword.get(opts, :initial_state, %{})
    state = struct!(%RatesServer{}, initial_state)

    name = Keyword.get(opts, :name, @default_name)

    GenServer.start_link(__MODULE__, state, name: via_tuple(name))
  end

  def get_state(server \\ @default_name) do
    GenServer.call(via_tuple(server), :get_state)
  end

  def add_currency(new_wallet, server \\ @default_name) do
    GenServer.call(via_tuple(server), {:add_currency, new_wallet})
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
  def handle_call(:get_state, _from, state) do
    {:reply, state, state}
  end

  @impl true
  def handle_call({:add_currency, new_wallet}, _from, state) do
    new_currency_count = Wallets.add_currency(new_wallet, state.currency_count)
    {:reply, :ok, %{state | currency_count: new_currency_count}}
  end

  @impl true
  def handle_info(:tick, state) do
    updated_rates = fetch_exchange_rates(state)

    {:noreply, %{state | rates: updated_rates}}
  end

  def fetch_exchange_rates(%RatesServer{} = state) do
    state.currency_count
    |> Wallets.get_exchange_combinations()
    |> Task.async_stream(fn {from, to} ->
      state.rates_api_module.fetch_rates(from, to)
    end)
    |> Helpers.handle_responses(state)
  end
end
