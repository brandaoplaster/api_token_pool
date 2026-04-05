defmodule ApiTokenPool.Accounts.UserTest do
  use ApiTokenPool.DataCase, async: true

  alias ApiTokenPool.Accounts.User

  describe "changeset/2" do
    test "valid with correct attributes" do
      assert %{valid?: true} = User.changeset(%User{}, %{name: "John Doe"})
    end

    test "invalid without name" do
      assert %{valid?: false} = User.changeset(%User{}, %{})
    end

    test "invalid with empty name" do
      assert %{valid?: false} = User.changeset(%User{}, %{name: ""})
    end

    test "invalid with name longer than 255 characters" do
      assert %{valid?: false} = User.changeset(%User{}, %{name: String.duplicate("a", 256)})
    end
  end
end
