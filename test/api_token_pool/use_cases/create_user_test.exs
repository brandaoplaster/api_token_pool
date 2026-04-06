defmodule ApiTokenPool.UseCases.CreateUserTest do
  use ApiTokenPool.DataCase, async: true

  alias ApiTokenPool.UseCases.CreateUser

  describe "execute/1" do
    test "creates user with valid attributes" do
      attrs = %{name: "Jane Doe"}

      assert {:ok, user} = CreateUser.execute(attrs)
      assert user.name == "Jane Doe"
      assert user.id
    end

    test "returns error when name is missing" do
      assert {:error, changeset} = CreateUser.execute(%{})
      assert "can't be blank" in errors_on(changeset).name
    end

    test "returns error when name is empty" do
      assert {:error, changeset} = CreateUser.execute(%{name: ""})
      assert "can't be blank" in errors_on(changeset).name
    end
  end
end
