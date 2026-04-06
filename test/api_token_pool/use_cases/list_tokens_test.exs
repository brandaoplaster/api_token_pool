defmodule ApiTokenPool.UseCases.ListTokensTest do
  use ApiTokenPool.DataCase, async: true
  import ApiTokenPool.Factory

  alias ApiTokenPool.UseCases.ListTokens

  describe "execute/0" do
    test "returns all tokens when multiple tokens exist" do
      token1 = insert(:token)
      token2 = insert(:token)
      token3 = insert(:allocated_token)

      tokens = ListTokens.execute()
      token_ids = Enum.map(tokens, & &1.id)

      assert length(tokens) == 3
      assert token1.id in token_ids
      assert token2.id in token_ids
      assert token3.id in token_ids
    end

    test "returns empty list when no tokens exist" do
      assert ListTokens.execute() == []
    end

    test "returns only available tokens when all are available" do
      insert(:token)
      insert(:token)

      tokens = ListTokens.execute()

      assert length(tokens) == 2
      assert Enum.all?(tokens, fn token -> token.status == :available end)
    end

    test "returns only allocated tokens when all are allocated" do
      insert(:allocated_token)
      insert(:allocated_token)

      tokens = ListTokens.execute()

      assert length(tokens) == 2
      assert Enum.all?(tokens, fn token -> token.status == :allocated end)
    end

    test "returns mixed status tokens" do
      insert(:token)
      insert(:allocated_token)

      tokens = ListTokens.execute()

      assert length(tokens) == 2
      assert Enum.any?(tokens, fn t -> t.status == :available end)
      assert Enum.any?(tokens, fn t -> t.status == :allocated end)
    end

    test "returns tokens with correct structure" do
      token = insert(:token)

      [result] = ListTokens.execute()

      assert result.id == token.id
      assert result.status == :available
      assert is_nil(result.allocated_at)
      assert is_nil(result.user_id)
      assert result.inserted_at
      assert result.updated_at
    end

    test "returns large number of tokens" do
      Enum.each(1..50, fn _ -> insert(:token) end)

      tokens = ListTokens.execute()

      assert length(tokens) == 50
    end
  end
end
