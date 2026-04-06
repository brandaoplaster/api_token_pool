defmodule ApiTokenPool.UseCases.ListTokens do
  alias ApiTokenPool.Repositories.TokenRepository

  def execute do
    TokenRepository.list_all()
  end
end
