defmodule ExChange.Rates.RatesSuperviser do
  use Supervisor

  def start_link(init_arg) do
    Supervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @impl true
  def init(_init_arg) do
    children =
      if Mix.env() == :test do
        []
      else
        [ExChange.Rates]
      end

    Supervisor.init(children, strategy: :one_for_one)
  end
end
