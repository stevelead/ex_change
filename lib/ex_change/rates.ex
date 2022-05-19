defmodule ExChange.Rates do
  use GenServer

  alias ExChange.Rates
  alias ExChange.Rates.RatesApi

  @default_name ExChange.Rates
  @default_tick_rate :timer.seconds(1)

  defstruct rates: [],
            wallet_currency_count: [],
            rates_api: RatesApi,
            tick_rate: @default_tick_rate

  # API

  def start_link(opts \\ []) do
    initial_state = Keyword.get(opts, :initial_state, %{})
    state = Map.merge(%Rates{}, initial_state)

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
    {:ok, state}
  end

  @impl true
  def handle_call(:state, _from, state) do
    {:reply, state, state}
  end
end
