defmodule ApiTokenPool.Factory do
  use ExMachina.Ecto, repo: ApiTokenPool.Repo

  use ApiTokenPool.UserFactory
  use ApiTokenPool.TokenFactory
  use ApiTokenPool.UsageHistoryFactory
end
