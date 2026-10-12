defmodule Subtrack.Repo do
  use Ecto.Repo,
    otp_app: :subtrack,
    adapter: Ecto.Adapters.Postgres
end
