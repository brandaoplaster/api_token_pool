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
end
