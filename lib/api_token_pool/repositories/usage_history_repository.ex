defmodule ApiTokenPool.Repositories.UsageHistoryRepository do
  import Ecto.Query

  alias ApiTokenPool.Repo
  alias ApiTokenPool.Tokens.UsageHistory

  def create(token, user_id) do
    %UsageHistory{}
    |> UsageHistory.changeset(%{
      token_id: token.id,
      user_id: user_id,
      started_at: DateTime.truncate(DateTime.utc_now(), :second)
    })
    |> Repo.insert()
  end

  def list_by_token(token_id) do
    UsageHistory
    |> where([h], h.token_id == ^token_id)
    |> order_by([h], desc: h.started_at)
    |> Repo.all()
  end

  def close(token_id) do
    UsageHistory
    |> where([h], h.token_id == ^token_id and is_nil(h.ended_at))
    |> Repo.one()
    |> case do
      nil -> {:error, :not_found}
      history -> history |> UsageHistory.close_changeset() |> Repo.update()
    end
  end
end
