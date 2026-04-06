defmodule ApiTokenPool.Workers.ReleaseTokenWorker do
  use Oban.Worker, queue: :tokens, max_attempts: 3

  alias ApiTokenPool.Repo
  alias ApiTokenPool.Repositories.TokenRepository
  alias ApiTokenPool.Repositories.UsageHistoryRepository
  alias ApiTokenPool.Tokens.Token

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"token_id" => token_id}}) do
    case TokenRepository.get(token_id) do
      %Token{status: :allocated} = token -> release(token)
      %Token{status: :available} -> :ok
      nil -> :ok
    end
  end

  defp release(token) do
    case Repo.transaction(fn -> do_release(token) end) do
      {:ok, _} -> :ok
      {:error, reason} -> {:error, reason}
    end
  end

  defp do_release(token) do
    with {:ok, _} <- TokenRepository.release(token),
         {:ok, _} <- UsageHistoryRepository.close(token.id) do
      :ok
    else
      {:error, reason} -> Repo.rollback(reason)
    end
  end
end
