defmodule ApiTokenPool.UseCases.GetTokenTest do
  use ApiTokenPool.DataCase, async: true
  import ApiTokenPool.Factory

  alias ApiTokenPool.UseCases.GetToken

  describe "execute/1" do
    test "returns {:ok, token} when token exists" do
      token = insert(:token)

      assert {:ok, result} = GetToken.execute(token.id)
      assert result.id == token.id
      assert result.status == :available
    end

    test "returns available token with correct attributes" do
      token = insert(:token)

      assert {:ok, result} = GetToken.execute(token.id)
      assert result.status == :available
      assert is_nil(result.allocated_at)
      assert is_nil(result.user_id)
    end

    test "returns allocated token with correct attributes" do
      token = insert(:allocated_token)

      assert {:ok, result} = GetToken.execute(token.id)
      assert result.status == :allocated
      refute is_nil(result.allocated_at)
      refute is_nil(result.user_id)
    end

    test "returns token with timestamps" do
      token = insert(:token)

      assert {:ok, result} = GetToken.execute(token.id)
      assert result.inserted_at
      assert result.updated_at
    end

    test "returns token with all fields" do
      token = insert(:token)

      assert {:ok, result} = GetToken.execute(token.id)
      assert result.id == token.id
      assert result.status == token.status
      assert result.allocated_at == token.allocated_at
      assert result.user_id == token.user_id
    end

    test "returns {:error, :not_found} when token does not exist" do
      non_existent_id = Ecto.UUID.generate()

      assert {:error, :not_found} = GetToken.execute(non_existent_id)
    end

    test "returns {:error, :not_found} when token was deleted" do
      token = insert(:token)
      id = token.id

      Repo.delete(token)

      assert {:error, :not_found} = GetToken.execute(id)
    end

    test "returns {:error, :not_found} for different non-existent tokens" do
      id1 = Ecto.UUID.generate()
      id2 = Ecto.UUID.generate()
      id3 = Ecto.UUID.generate()

      assert {:error, :not_found} = GetToken.execute(id1)
      assert {:error, :not_found} = GetToken.execute(id2)
      assert {:error, :not_found} = GetToken.execute(id3)
    end

    test "returns {:error, :invalid_uuid} when id has invalid format" do
      assert {:error, :invalid_uuid} = GetToken.execute("invalid-uuid")
    end

    test "returns {:error, :invalid_uuid} when id is nil" do
      assert {:error, :invalid_uuid} = GetToken.execute(nil)
    end

    test "returns {:error, :invalid_uuid} when id is empty string" do
      assert {:error, :invalid_uuid} = GetToken.execute("")
    end
  end

  describe "execute/1 - integration scenarios" do
    test "can get token that was just created" do
      token = insert(:token)

      assert {:ok, result} = GetToken.execute(token.id)
      assert result.id == token.id
    end

    test "cannot get token after deletion" do
      token = insert(:token)
      Repo.delete(token)

      assert {:error, :not_found} = GetToken.execute(token.id)
    end

    test "multiple sequential gets return consistent results" do
      token = insert(:token)

      assert {:ok, result1} = GetToken.execute(token.id)
      assert {:ok, result2} = GetToken.execute(token.id)
      assert {:ok, result3} = GetToken.execute(token.id)

      assert result1.id == result2.id
      assert result2.id == result3.id
    end
  end

  describe "execute_history/1" do
    test "returns empty list when token has no history" do
      token = insert(:token)

      assert {:ok, []} = GetToken.execute_history(token.id)
    end

    test "returns histories ordered by started_at desc" do
      token = insert(:token)
      history1 = insert(:usage_history, token: token, started_at: ~U[2024-01-01 10:00:00Z])
      history2 = insert(:usage_history, token: token, started_at: ~U[2024-01-02 10:00:00Z])

      assert {:ok, histories} = GetToken.execute_history(token.id)
      assert [history2.id, history1.id] == Enum.map(histories, & &1.id)
    end

    test "returns only histories for specified token" do
      token1 = insert(:token)
      token2 = insert(:token)
      history1 = insert(:usage_history, token: token1)
      insert(:usage_history, token: token2)

      assert {:ok, [result]} = GetToken.execute_history(token1.id)
      assert result.id == history1.id
    end

    test "returns error when token not found" do
      assert {:error, :not_found} = GetToken.execute_history(Ecto.UUID.generate())
    end

    test "returns error when invalid uuid" do
      assert {:error, :invalid_uuid} = GetToken.execute_history("invalid")
      assert {:error, :invalid_uuid} = GetToken.execute_history(nil)
    end
  end
end
