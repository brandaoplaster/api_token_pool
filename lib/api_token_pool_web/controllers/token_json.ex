defmodule ApiTokenPoolWeb.TokenJSON do
  def index(%{tokens: tokens}), do: %{data: Enum.map(tokens, &data/1)}
  def show(%{token: token}), do: %{data: data(token)}
  def allocate(%{token: token}), do: %{data: %{token_id: token.id, user_id: token.user_id}}
  def history(%{history: history}), do: %{data: Enum.map(history, &history_data/1)}
  def release_active(%{count: count}), do: %{data: %{released: count}}

  defp data(token) do
    %{
      id: token.id,
      status: token.status,
      user_id: token.user_id,
      allocated_at: token.allocated_at
    }
  end

  defp history_data(h) do
    %{
      user_id: h.user_id,
      started_at: h.started_at,
      ended_at: h.ended_at
    }
  end
end
