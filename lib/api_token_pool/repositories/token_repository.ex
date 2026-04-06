defmodule ApiTokenPool.Repositories.TokenRepository do
  import Ecto.Query, warn: false

  alias ApiTokenPool.Repo
  alias ApiTokenPool.Tokens.Token

  def list_all do
    Repo.all(Token)
  end

  def get(id) do
    Repo.get(Token, id)
  end

  def allocate(token, user_id) do
    token
    |> Token.allocate_changeset(%{
      user_id: user_id,
      allocated_at: DateTime.truncate(DateTime.utc_now(), :second)
    })
    |> Repo.update()
  end

  def release(token) do
    token
    |> Token.release_changeset()
    |> Repo.update()
  end

  def get_available do
    Token
    |> where([t], t.status == :available)
    |> limit(1)
    |> lock("FOR UPDATE SKIP LOCKED")
    |> Repo.one()
  end

  def release_oldest do
    token =
      Token
      |> where([t], t.status == :allocated)
      |> order_by([t], asc: t.allocated_at)
      |> limit(1)
      |> lock("FOR UPDATE SKIP LOCKED")
      |> Repo.one()

    case token do
      nil -> {:error, :no_tokens_available}
      token -> token |> Token.release_changeset() |> Repo.update()
    end
  end

  def list_allocated do
    Token
    |> where([t], t.status == :allocated)
    |> Repo.all()
  end
end
