defmodule ApiTokenPool.Repo do
  use Ecto.Repo,
    otp_app: :api_token_pool,
    adapter: Ecto.Adapters.Postgres
end
