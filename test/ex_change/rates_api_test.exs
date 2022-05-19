defmodule ExChange.RatesApiTest do
  use ExUnit.Case
  require Decimal

  alias ExChange.RatesApi.Rate

  describe "RatesServer.Rate.new/3" do
    test "accepts a rate as binary and returns a Decimal" do
      assert %{rate: rate} = Rate.new("NZD:USD", "0.65")

      assert Decimal.is_decimal(rate)
    end
  end
end
