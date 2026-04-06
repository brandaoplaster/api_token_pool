defmodule ApiTokenPool.UseCases.GetToken do
  alias ApiTokenPool.Repositories.{TokenRepository, UsageHistoryRepository}

  def execute(id) when is_binary(id) do
    case Ecto.UUID.cast(id) do
      {:ok, _} -> fetch(id)
      :error -> {:error, :invalid_uuid}
    end
  end

  def execute(_id), do: {:error, :invalid_uuid}

  def execute_history(id) when is_binary(id) do
    with {:ok, _} <- Ecto.UUID.cast(id),
         token when not is_nil(token) <- TokenRepository.get(id) do
      {:ok, UsageHistoryRepository.list_by_token(token.id)}
    else
      :error -> {:error, :invalid_uuid}
      nil -> {:error, :not_found}
    end
  end

  def execute_history(_id), do: {:error, :invalid_uuid}

  defp fetch(id) do
    case TokenRepository.get(id) do
      nil -> {:error, :not_found}
      token -> {:ok, token}
    end
  end
end
