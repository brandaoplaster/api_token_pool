defmodule ApiTokenPool.UseCases.ListUsersTest do
  use ApiTokenPool.DataCase, async: true
  import ApiTokenPool.Factory

  alias ApiTokenPool.UseCases.ListUsers

  describe "execute/0" do
    test "returns empty list when no users exist" do
      assert ListUsers.execute() == []
    end

    test "returns all users" do
      user1 = insert(:user)
      user2 = insert(:user)

      users = ListUsers.execute()

      assert length(users) == 2
      assert user1.id in Enum.map(users, & &1.id)
      assert user2.id in Enum.map(users, & &1.id)
    end
  end
end
