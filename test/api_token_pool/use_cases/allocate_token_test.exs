defmodule ApiTokenPool.UseCases.AllocateTokenTest do
  use ApiTokenPool.DataCase, async: true
  use Oban.Testing, repo: ApiTokenPool.Repo

  import ApiTokenPool.Factory

  alias ApiTokenPool.Repositories.{TokenRepository, UsageHistoryRepository}
  alias ApiTokenPool.UseCases.AllocateToken
  alias ApiTokenPool.Workers.ReleaseTokenWorker

  describe "execute/1 - positive cases" do
    test "allocates available token to user" do
      token = insert(:token)
      user = insert(:user)

      assert {:ok, result} = AllocateToken.execute(user.id)
      assert result.id == token.id
      assert result.status == :allocated
      assert result.user_id == user.id
      assert result.allocated_at
    end

    test "creates usage history when allocating token" do
      insert(:token)
      user = insert(:user)

      {:ok, token} = AllocateToken.execute(user.id)

      histories = UsageHistoryRepository.list_by_token(token.id)
      assert length(histories) == 1

      history = hd(histories)
      assert history.token_id == token.id
      assert history.user_id == user.id
      assert history.started_at
      assert is_nil(history.ended_at)
    end

    test "releases oldest token when no available tokens" do
      user1 = insert(:user)
      user2 = insert(:user)
      token = insert(:token)

      {:ok, _} = AllocateToken.execute(user1.id)

      assert {:ok, result} = AllocateToken.execute(user2.id)
      assert result.id == token.id
      assert result.user_id == user2.id
    end

    test "closes old history when releasing oldest token" do
      user1 = insert(:user)
      user2 = insert(:user)
      insert(:token)

      {:ok, token1} = AllocateToken.execute(user1.id)
      {:ok, _token2} = AllocateToken.execute(user2.id)

      histories = UsageHistoryRepository.list_by_token(token1.id)

      assert Enum.any?(histories, fn h -> h.ended_at && h.user_id == user1.id end)
    end

    test "allocates to different users sequentially" do
      insert(:token)
      user1 = insert(:user)
      user2 = insert(:user)

      {:ok, result1} = AllocateToken.execute(user1.id)
      assert result1.user_id == user1.id

      {:ok, result2} = AllocateToken.execute(user2.id)
      assert result2.user_id == user2.id
    end

    test "schedules a release job when allocating token" do
      user = insert(:user)
      insert(:token, status: :available)

      now = DateTime.utc_now()
      assert {:ok, token} = AllocateToken.execute(user.id)

      [job] = all_enqueued(worker: ReleaseTokenWorker)

      assert job.args == %{"token_id" => token.id}
      assert job.worker == "ApiTokenPool.Workers.ReleaseTokenWorker"

      scheduled_diff = DateTime.diff(job.scheduled_at, now, :second)
      assert scheduled_diff >= 119 and scheduled_diff <= 121
    end
  end

  describe "execute/1 - negative cases" do
    test "returns error when user_id is invalid uuid" do
      insert(:token)

      assert {:error, _} = AllocateToken.execute("invalid-uuid")
    end

    test "returns error when user_id is nil" do
      insert(:token)

      assert {:error, _} = AllocateToken.execute(nil)
    end

    test "returns error when user_id is empty string" do
      insert(:token)

      assert {:error, _} = AllocateToken.execute("")
    end

    test "returns error when no tokens exist" do
      user = insert(:user)

      assert {:error, :no_tokens_available} = AllocateToken.execute(user.id)
    end

    test "rollback when allocation fails" do
      token = insert(:token)
      user = insert(:user)

      Repo.delete(token)

      assert {:error, _} = AllocateToken.execute(user.id)

      assert TokenRepository.list_all() == []
    end
  end
end
