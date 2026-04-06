defmodule ApiTokenPool.UseCases.ReleaseActiveTokens do
  alias ApiTokenPool.Repo
  alias ApiTokenPool.Repositories.TokenRepository
  alias ApiTokenPool.Repositories.UsageHistoryRepository

  def execute do
    Repo.transaction(fn ->
      tokens = TokenRepository.list_allocated()
      Enum.each(tokens, &release_token/1)
      length(tokens)
    end)
  end

  defp release_token(token) do
    with {:ok, _} <- TokenRepository.release(token),
         {:ok, _} <- UsageHistoryRepository.close(token.id) do
      :ok
    else
      {:error, reason} -> Repo.rollback(reason)
    end
  end
end
