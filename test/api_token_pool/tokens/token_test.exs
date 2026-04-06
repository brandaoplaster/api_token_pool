defmodule ApiTokenPool.Tokens.TokenTest do
  use ApiTokenPool.DataCase, async: true
  import ApiTokenPool.Factory

  alias ApiTokenPool.Tokens.Token

  describe "changeset/2" do
    test "valid with allocated_at" do
      token = build(:token)
      at = DateTime.truncate(DateTime.utc_now(), :second)

      assert %{valid?: true, changes: %{allocated_at: ^at}} =
               Token.changeset(token, %{allocated_at: at})
    end

    test "valid with status available" do
      token = build(:token, status: :allocated)

      assert %{valid?: true, changes: %{status: :available}} =
               Token.changeset(token, %{status: :available})
    end

    test "valid with status allocated" do
      token = build(:token)

      assert %{valid?: true, changes: %{status: :allocated}} =
               Token.changeset(token, %{status: :allocated})
    end

    test "invalid with invalid status" do
      token = build(:token)

      assert %{valid?: false, errors: [status: _]} =
               Token.changeset(token, %{status: :invalid_status})
    end

    test "valid with empty attributes" do
      token = insert(:token)

      assert %{valid?: true, changes: %{}} = Token.changeset(token, %{})
    end

    test "valid when clearing allocated_at" do
      token = insert(:allocated_token)

      assert %{valid?: true, changes: %{allocated_at: nil}} =
               Token.changeset(token, %{allocated_at: nil})
    end

    test "ignores keys other than allocated_at and status" do
      user = insert(:user)
      token = build(:token)
      at = DateTime.truncate(DateTime.utc_now(), :second)

      changeset =
        Token.changeset(token, %{allocated_at: at, user_id: user.id, status: :allocated})

      assert changeset.valid?
      assert changeset.changes == %{allocated_at: at, status: :allocated}
    end

    test "invalid with invalid allocated_at type" do
      token = build(:token)

      assert %{valid?: false, errors: [allocated_at: _]} =
               Token.changeset(token, %{allocated_at: "not-a-datetime"})
    end
  end

  describe "allocate_changeset/2" do
    test "valid with user_id and allocated_at" do
      user = insert(:user)
      token = insert(:token)
      attrs = %{user_id: user.id, allocated_at: DateTime.truncate(DateTime.utc_now(), :second)}

      changeset = Token.allocate_changeset(token, attrs)

      assert changeset.valid?
      assert changeset.changes.status == :allocated
    end

    test "sets status to allocated automatically" do
      user = insert(:user)
      token = insert(:token)
      attrs = %{user_id: user.id, allocated_at: DateTime.truncate(DateTime.utc_now(), :second)}

      changeset = Token.allocate_changeset(token, attrs)

      assert changeset.changes.status == :allocated
    end

    test "invalid without user_id" do
      token = insert(:token)
      attrs = %{allocated_at: DateTime.truncate(DateTime.utc_now(), :second)}

      assert %{valid?: false} = Token.allocate_changeset(token, attrs)
    end

    test "invalid without allocated_at" do
      user = insert(:user)
      token = insert(:token)

      assert %{valid?: false} = Token.allocate_changeset(token, %{user_id: user.id})
    end
  end

  describe "release_changeset/1" do
    test "clears user_id, allocated_at and sets status to available" do
      token = insert(:allocated_token)
      changeset = Token.release_changeset(token)

      assert changeset.changes == %{user_id: nil, allocated_at: nil, status: :available}
    end
  end
end
