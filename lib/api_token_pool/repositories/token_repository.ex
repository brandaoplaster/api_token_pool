defmodule ApiTokenPool.Repositories.TokenRepository do
  alias ApiTokenPool.Repo
  alias ApiTokenPool.Tokens.Token

  def list_all do
    Repo.all(Token)
  end

  def get(id) do
    Repo.get(Token, id)
  end
end
