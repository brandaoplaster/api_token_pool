defmodule ApiTokenPool.Repositories.TokenRepositoryTest do
  use ApiTokenPool.DataCase, async: true
  import ApiTokenPool.Factory

  alias ApiTokenPool.Repositories.TokenRepository

  describe "list_all/0" do
    test "returns all tokens when multiple tokens exist" do
      token1 = insert(:token)
      token2 = insert(:token)
      token3 = insert(:allocated_token)

      tokens = TokenRepository.list_all()
      token_ids = Enum.map(tokens, & &1.id)

      assert length(tokens) == 3
      assert token1.id in token_ids
      assert token2.id in token_ids
      assert token3.id in token_ids
    end

    test "returns empty list when no tokens exist" do
      assert TokenRepository.list_all() == []
    end

    test "returns only available tokens when all are available" do
      insert(:token)
      insert(:token)
      insert(:token)

      tokens = TokenRepository.list_all()

      assert length(tokens) == 3
      assert Enum.all?(tokens, fn token -> token.status == :available end)
    end

    test "returns only allocated tokens when all are allocated" do
      insert(:allocated_token)
      insert(:allocated_token)

      tokens = TokenRepository.list_all()

      assert length(tokens) == 2
      assert Enum.all?(tokens, fn token -> token.status == :allocated end)
    end

    test "returns mixed status tokens" do
      insert(:token)
      insert(:allocated_token)

      tokens = TokenRepository.list_all()

      assert length(tokens) == 2
      assert Enum.any?(tokens, fn t -> t.status == :available end)
      assert Enum.any?(tokens, fn t -> t.status == :allocated end)
    end

    test "returns tokens with all fields populated correctly" do
      token = insert(:token)

      [result] = TokenRepository.list_all()

      assert result.id == token.id
      assert result.status == token.status
      assert result.allocated_at == token.allocated_at
      assert result.user_id == token.user_id
    end

    test "returns large number of tokens efficiently" do
      Enum.each(1..100, fn _ -> insert(:token) end)

      tokens = TokenRepository.list_all()

      assert length(tokens) == 100
    end
  end

  describe "get/1" do
    test "returns token when valid id is provided" do
      token = insert(:token)

      result = TokenRepository.get(token.id)

      assert result.id == token.id
      assert result.status == token.status
    end

    test "returns available token with correct attributes" do
      token = insert(:token)

      result = TokenRepository.get(token.id)

      assert result.status == :available
      assert is_nil(result.allocated_at)
      assert is_nil(result.user_id)
    end

    test "returns allocated token with user association" do
      token = insert(:allocated_token)

      result = TokenRepository.get(token.id)

      assert result.status == :allocated
      refute is_nil(result.allocated_at)
      refute is_nil(result.user_id)
    end

    test "returns token with timestamps" do
      token = insert(:token)

      result = TokenRepository.get(token.id)

      assert result.inserted_at
      assert result.updated_at
    end

    test "returns nil when token does not exist" do
      non_existent_id = Ecto.UUID.generate()

      assert is_nil(TokenRepository.get(non_existent_id))
    end

    test "returns nil when token was deleted" do
      token = insert(:token)
      id = token.id

      Repo.delete(token)

      assert is_nil(TokenRepository.get(id))
    end
  end

  describe "integration scenarios" do
    test "list_all and get return consistent data" do
      token1 = insert(:token)
      token2 = insert(:allocated_token)

      all_tokens = TokenRepository.list_all()
      fetched_token1 = TokenRepository.get(token1.id)
      fetched_token2 = TokenRepository.get(token2.id)

      token_ids = Enum.map(all_tokens, & &1.id)

      assert length(all_tokens) == 2
      assert fetched_token1.id in token_ids
      assert fetched_token2.id in token_ids
    end

    test "get returns token that exists in list_all" do
      token = insert(:token)

      all_tokens = TokenRepository.list_all()
      fetched_token = TokenRepository.get(token.id)

      token_ids = Enum.map(all_tokens, & &1.id)

      assert fetched_token.id in token_ids
    end
  end

  describe "allocate/2" do
    test "allocates available token to user" do
      token = insert(:token)
      user = insert(:user)

      assert {:ok, updated} = TokenRepository.allocate(token, user.id)
      assert updated.status == :allocated
      assert updated.user_id == user.id
      assert updated.allocated_at
    end

    test "allocated_at has no microseconds" do
      token = insert(:token)
      user = insert(:user)

      {:ok, updated} = TokenRepository.allocate(token, user.id)

      assert updated.allocated_at.microsecond == {0, 0}
    end

    test "updates existing allocated token to new user" do
      user1 = insert(:user)
      user2 = insert(:user)
      token = insert(:allocated_token, user: user1)

      assert {:ok, updated} = TokenRepository.allocate(token, user2.id)
      assert updated.user_id == user2.id
      assert updated.status == :allocated
    end
  end

  describe "release/1" do
    test "releases allocated token" do
      token = insert(:allocated_token)

      assert {:ok, updated} = TokenRepository.release(token)
      assert updated.status == :available
      assert is_nil(updated.user_id)
      assert is_nil(updated.allocated_at)
    end

    test "releases already available token" do
      token = insert(:token)

      assert {:ok, updated} = TokenRepository.release(token)
      assert updated.status == :available
      assert is_nil(updated.user_id)
      assert is_nil(updated.allocated_at)
    end
  end

  describe "get_available/0" do
    test "returns available token when one exists" do
      token = insert(:token)

      result = TokenRepository.get_available()

      assert result.id == token.id
      assert result.status == :available
    end

    test "returns nil when no available tokens exist" do
      insert(:allocated_token)
      insert(:allocated_token)

      assert is_nil(TokenRepository.get_available())
    end

    test "returns nil when no tokens exist" do
      assert is_nil(TokenRepository.get_available())
    end

    test "returns one token when multiple available" do
      insert(:token)
      insert(:token)
      insert(:token)

      result = TokenRepository.get_available()

      assert result
      assert result.status == :available
    end

    test "ignores allocated tokens" do
      insert(:allocated_token)
      available_token = insert(:token)

      result = TokenRepository.get_available()

      assert result.id == available_token.id
    end
  end

  describe "release_oldest/0" do
    test "releases oldest allocated token" do
      token1 = insert(:allocated_token, allocated_at: ~U[2024-01-01 10:00:00Z])
      token2 = insert(:allocated_token, allocated_at: ~U[2024-01-02 10:00:00Z])

      assert {:ok, released} = TokenRepository.release_oldest()
      assert released.id == token1.id
      assert released.status == :available
      assert is_nil(released.user_id)
      assert is_nil(released.allocated_at)

      token2_updated = TokenRepository.get(token2.id)
      assert token2_updated.status == :allocated
    end

    test "returns error when no allocated tokens exist" do
      insert(:token)
      insert(:token)

      assert {:error, :no_tokens_available} = TokenRepository.release_oldest()
    end

    test "returns error when no tokens exist" do
      assert {:error, :no_tokens_available} = TokenRepository.release_oldest()
    end

    test "ignores available tokens" do
      insert(:token)
      allocated = insert(:allocated_token, allocated_at: ~U[2024-01-01 10:00:00Z])

      assert {:ok, released} = TokenRepository.release_oldest()
      assert released.id == allocated.id
    end
  end
end
