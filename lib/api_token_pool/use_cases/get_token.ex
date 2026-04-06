defmodule ApiTokenPool.UseCases.GetToken do
  alias ApiTokenPool.Repositories.TokenRepository

  def execute(id) when is_binary(id) do
    case Ecto.UUID.cast(id) do
      {:ok, _} -> fetch(id)
      :error -> {:error, :invalid_uuid}
    end
  end

  def execute(_id), do: {:error, :invalid_uuid}

  defp fetch(id) do
    case TokenRepository.get(id) do
      nil -> {:error, :not_found}
      token -> {:ok, token}
    end
  end
end
