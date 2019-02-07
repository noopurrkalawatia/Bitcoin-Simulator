defmodule MyBitcoinSimulator.Repo do
  use Ecto.Repo,
    otp_app: :myBitcoinSimulator,
    adapter: Ecto.Adapters.Postgres
end
