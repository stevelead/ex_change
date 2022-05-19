defmodule Support.Fixtures.RatesFixtures do
  alias ExChange.Rates.Rate

  def rate_fixture() do
    Rate.new("NZD/USD", 0.55)
  end
end
