defmodule ExChange.Rates do
  use GenServer

  alias ExChange.Rates
  alias ExChange.Rates.RatesApi

  defstruct rates: [], wallet_currency_count: [], rates_api: RatesApi

  @default_name ExChange.Rates

  # API

  def start_link(opts \\ []) do
    initial_state = Keyword.get(opts, :initial_state, %{})

    state = Map.merge(%Rates{}, initial_state)

    name = Keyword.get(opts, :name, @default_name)
    GenServer.start_link(__MODULE__, state, name: via_name(name))
  end

  def via_name(name) when is_atom(name) or is_binary(name) do
    {:via, Registry, {ExChange.Registry, name}}
  end

  # Server

  @impl true
  def init(state) do
    {:ok, state}
  end
end
