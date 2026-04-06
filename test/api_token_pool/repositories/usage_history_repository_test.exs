defmodule ApiTokenPool.Repositories.UsageHistoryRepositoryTest do
  use ApiTokenPool.DataCase, async: true
  import ApiTokenPool.Factory

  alias ApiTokenPool.Repositories.UsageHistoryRepository

  describe "create/2" do
    test "creates usage history with valid token and user_id" do
      token = insert(:token)
      user = insert(:user)

      assert {:ok, history} = UsageHistoryRepository.create(token, user.id)
      assert history.token_id == token.id
      assert history.user_id == user.id
      assert history.started_at
      assert is_nil(history.ended_at)
    end

    test "creates with truncated datetime" do
      token = insert(:token)
      user = insert(:user)

      {:ok, history} = UsageHistoryRepository.create(token, user.id)

      assert history.started_at.microsecond == {0, 0}
    end
  end

  describe "list_by_token/1" do
    test "returns all usage histories for a token ordered by started_at desc" do
      token = insert(:token)
      history1 = insert(:usage_history, token: token, started_at: ~U[2024-01-01 10:00:00Z])
      history2 = insert(:usage_history, token: token, started_at: ~U[2024-01-02 10:00:00Z])
      history3 = insert(:usage_history, token: token, started_at: ~U[2024-01-03 10:00:00Z])

      result = UsageHistoryRepository.list_by_token(token.id)

      assert length(result) == 3
      assert [history3.id, history2.id, history1.id] == Enum.map(result, & &1.id)
    end

    test "returns empty list when no histories exist" do
      token = insert(:token)

      assert UsageHistoryRepository.list_by_token(token.id) == []
    end

    test "returns only histories for specified token" do
      token1 = insert(:token)
      token2 = insert(:token)
      history1 = insert(:usage_history, token: token1)
      insert(:usage_history, token: token2)

      result = UsageHistoryRepository.list_by_token(token1.id)

      assert length(result) == 1
      assert hd(result).id == history1.id
    end
  end

  describe "close/1" do
    test "closes open usage history for token" do
      token = insert(:token)
      history = insert(:usage_history, token: token, ended_at: nil)

      assert {:ok, updated} = UsageHistoryRepository.close(token.id)
      assert updated.id == history.id
      assert updated.ended_at
    end

    test "returns error when no open history exists" do
      token = insert(:token)

      assert {:error, :not_found} = UsageHistoryRepository.close(token.id)
    end

    test "ignores already closed histories" do
      token = insert(:token)
      insert(:usage_history, token: token, ended_at: DateTime.utc_now())

      assert {:error, :not_found} = UsageHistoryRepository.close(token.id)
    end

    test "closes only the open history when multiple histories exist" do
      token = insert(:token)
      closed_history = insert(:usage_history, token: token, ended_at: ~U[2024-01-01 10:00:00Z])
      open_history = insert(:usage_history, token: token, ended_at: nil)

      assert {:ok, updated} = UsageHistoryRepository.close(token.id)
      assert updated.id == open_history.id
      refute updated.id == closed_history.id
    end
  end
end
