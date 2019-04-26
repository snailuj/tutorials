defmodule Racebook.Repo do
  use Ecto.Repo,
    otp_app: :racebook,
    adapter: Ecto.Adapters.Postgres
end
