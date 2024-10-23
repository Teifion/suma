defmodule Fusion.Repo do
  use Ecto.Repo,
    otp_app: :fusion,
    adapter: Ecto.Adapters.Postgres
end
