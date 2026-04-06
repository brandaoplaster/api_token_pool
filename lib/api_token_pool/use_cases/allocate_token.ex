defmodule ApiTokenPool.UseCases.AllocateToken do
  alias ApiTokenPool.Repo
  alias ApiTokenPool.Repositories.{TokenRepository, UsageHistoryRepository}

  def execute(user_id) when is_binary(user_id) do
    case Ecto.UUID.cast(user_id) do
      {:ok, _} -> Repo.transaction(fn -> allocate(user_id) end)
      :error -> {:error, :invalid_uuid}
    end
  end

  def execute(_user_id), do: {:error, :invalid_uuid}

  defp allocate(user_id) do
    with {:ok, token} <- get_or_release_token(),
         {:ok, token} <- TokenRepository.allocate(token, user_id),
         {:ok, _} <- UsageHistoryRepository.create(token, user_id) do
      token
    else
      {:error, reason} -> Repo.rollback(reason)
    end
  end

  defp get_or_release_token do
    case TokenRepository.get_available() do
      nil -> release_and_close_history()
      token -> {:ok, token}
    end
  end

  defp release_and_close_history do
    with {:ok, token} <- TokenRepository.release_oldest(),
         {:ok, _} <- UsageHistoryRepository.close(token.id) do
      {:ok, token}
    end
  end
end
