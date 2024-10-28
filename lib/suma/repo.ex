defmodule Suma.Repo do
  use Ecto.Repo,
    otp_app: :suma,
    adapter: Ecto.Adapters.Postgres
end
