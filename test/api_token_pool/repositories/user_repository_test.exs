defmodule ApiTokenPool.Repositories.UserRepositoryTest do
  use ApiTokenPool.DataCase, async: true
  import ApiTokenPool.Factory

  alias ApiTokenPool.Repositories.UserRepository

  describe "list_all/0" do
    test "returns empty list when no users exist" do
      assert UserRepository.list_all() == []
    end

    test "returns all users" do
      user1 = insert(:user)
      user2 = insert(:user)

      users = UserRepository.list_all()

      assert length(users) == 2
      assert user1.id in Enum.map(users, & &1.id)
      assert user2.id in Enum.map(users, & &1.id)
    end
  end

  describe "get/1" do
    test "returns user when id exists" do
      user = insert(:user)

      assert found_user = UserRepository.get(user.id)
      assert found_user.id == user.id
      assert found_user.name == user.name
    end

    test "returns nil when user does not exist" do
      assert UserRepository.get(Ecto.UUID.generate()) == nil
    end
  end

  describe "create/1" do
    test "creates user with valid attributes" do
      attrs = %{name: "John Doe"}

      assert {:ok, user} = UserRepository.create(attrs)
      assert user.name == "John Doe"
      assert user.id
    end

    test "returns error when name is missing" do
      assert {:error, changeset} = UserRepository.create(%{})
      assert "can't be blank" in errors_on(changeset).name
    end

    test "returns error when name is empty" do
      assert {:error, changeset} = UserRepository.create(%{name: ""})
      assert "can't be blank" in errors_on(changeset).name
    end
  end
end
