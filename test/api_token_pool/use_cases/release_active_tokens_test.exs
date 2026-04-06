defmodule ApiTokenPool.UseCases.ReleaseActiveTokensTest do
  use ApiTokenPool.DataCase, async: true
  import ApiTokenPool.Factory

  alias ApiTokenPool.Repositories.{TokenRepository, UsageHistoryRepository}
  alias ApiTokenPool.UseCases.ReleaseActiveTokens

  defp create_allocated_token_with_history do
    token = insert(:allocated_token)
    insert(:usage_history, token: token, ended_at: nil)
    token
  end

  describe "execute/0 - positive cases" do
    test "releases all allocated tokens" do
      token1 = create_allocated_token_with_history()
      token2 = create_allocated_token_with_history()

      assert {:ok, 2} = ReleaseActiveTokens.execute()

      updated1 = TokenRepository.get(token1.id)
      updated2 = TokenRepository.get(token2.id)

      assert updated1.status == :available
      assert updated2.status == :available
      assert is_nil(updated1.user_id)
      assert is_nil(updated2.user_id)
    end

    test "closes all usage histories" do
      token1 = create_allocated_token_with_history()
      token2 = create_allocated_token_with_history()

      {:ok, _} = ReleaseActiveTokens.execute()

      histories1 = UsageHistoryRepository.list_by_token(token1.id)
      histories2 = UsageHistoryRepository.list_by_token(token2.id)

      assert Enum.all?(histories1, & &1.ended_at)
      assert Enum.all?(histories2, & &1.ended_at)
    end

    test "returns count of released tokens" do
      create_allocated_token_with_history()
      create_allocated_token_with_history()
      create_allocated_token_with_history()

      assert {:ok, 3} = ReleaseActiveTokens.execute()
    end

    test "returns 0 when no allocated tokens" do
      insert(:token)
      insert(:token)

      assert {:ok, 0} = ReleaseActiveTokens.execute()
    end

    test "ignores available tokens" do
      token = insert(:token)
      create_allocated_token_with_history()

      {:ok, count} = ReleaseActiveTokens.execute()

      assert count == 1
      updated = TokenRepository.get(token.id)
      assert updated.status == :available
    end

    test "releases only allocated tokens when mixed" do
      available = insert(:token)
      allocated1 = create_allocated_token_with_history()
      allocated2 = create_allocated_token_with_history()

      {:ok, count} = ReleaseActiveTokens.execute()

      assert count == 2
      assert TokenRepository.get(available.id).status == :available
      assert TokenRepository.get(allocated1.id).status == :available
      assert TokenRepository.get(allocated2.id).status == :available
    end
  end

  describe "execute/0 - negative cases" do
    test "returns 0 when no tokens exist" do
      assert {:ok, 0} = ReleaseActiveTokens.execute()
    end
  end
end
