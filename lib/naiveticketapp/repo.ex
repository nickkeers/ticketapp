defmodule Naiveticketapp.Repo do
  use Ecto.Repo,
    otp_app: :naiveticketapp,
    adapter: Ecto.Adapters.Postgres
end
