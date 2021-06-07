defmodule Gaveld.Repo do
  use Ecto.Repo,
    otp_app: :gaveld,
    adapter: Ecto.Adapters.Postgres
end
