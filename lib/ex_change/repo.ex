defmodule ExChange.Repo do
  use Ecto.Repo,
    otp_app: :ex_change,
    adapter: Ecto.Adapters.Postgres
end
