defmodule ApiTokenPool.Tokens.UsageHistoryTest do
  use ApiTokenPool.DataCase, async: true

  import ApiTokenPool.Factory

  alias ApiTokenPool.Tokens.UsageHistory

  describe "changeset/2" do
    test "valid with correct attributes" do
      user = insert(:user)
      token = insert(:token)

      attrs = %{
        token_id: token.id,
        user_id: user.id,
        started_at: DateTime.truncate(DateTime.utc_now(), :second)
      }

      assert %{valid?: true} = UsageHistory.changeset(%UsageHistory{}, attrs)
    end

    test "invalid without token_id" do
      user = insert(:user)
      attrs = %{user_id: user.id, started_at: DateTime.truncate(DateTime.utc_now(), :second)}

      assert %{valid?: false} = UsageHistory.changeset(%UsageHistory{}, attrs)
    end

    test "invalid without user_id" do
      token = insert(:token)
      attrs = %{token_id: token.id, started_at: DateTime.truncate(DateTime.utc_now(), :second)}

      assert %{valid?: false} = UsageHistory.changeset(%UsageHistory{}, attrs)
    end

    test "invalid without started_at" do
      user = insert(:user)
      token = insert(:token)

      assert %{valid?: false} =
               UsageHistory.changeset(%UsageHistory{}, %{token_id: token.id, user_id: user.id})
    end
  end

  describe "close_changeset/1" do
    test "fills ended_at" do
      history = insert(:usage_history)
      changeset = UsageHistory.close_changeset(history)

      assert changeset.changes.ended_at != nil
    end
  end
end
