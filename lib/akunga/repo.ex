defmodule Akunga.Repo do
  use Ecto.Repo,
    otp_app: :akunga,
    adapter: Ecto.Adapters.Postgres
end
