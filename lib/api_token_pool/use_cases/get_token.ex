defmodule ApiTokenPool.UseCases.GetToken do
  alias ApiTokenPool.Repositories.TokenRepository

  def execute(id) do
    case TokenRepository.get(id) do
      nil -> {:error, :not_found}
      token -> {:ok, token}
    end
  end
end
