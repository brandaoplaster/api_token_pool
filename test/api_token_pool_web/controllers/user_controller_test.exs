defmodule ApiTokenPoolWeb.UserControllerTest do
  use ApiTokenPoolWeb.ConnCase, async: true
  import ApiTokenPool.Factory

  describe "GET /api/users (index)" do
    test "returns empty list when no users exist", %{conn: conn} do
      conn = get(conn, ~p"/api/users")

      assert json_response(conn, 200) == %{"data" => []}
    end

    test "returns all users when multiple exist", %{conn: conn} do
      user1 = insert(:user)
      user2 = insert(:user)

      conn = get(conn, ~p"/api/users")

      response = json_response(conn, 200)
      assert length(response["data"]) == 2

      user_ids = Enum.map(response["data"], & &1["id"])
      assert user1.id in user_ids
      assert user2.id in user_ids
    end

    test "returns users with correct structure", %{conn: conn} do
      user = insert(:user, name: "Test User")

      conn = get(conn, ~p"/api/users")

      assert %{"data" => [user_data]} = json_response(conn, 200)
      assert user_data["id"] == user.id
      assert user_data["name"] == "Test User"
      assert user_data["inserted_at"]
      assert user_data["updated_at"]
    end

    test "returns 200 status code", %{conn: conn} do
      insert(:user)

      conn = get(conn, ~p"/api/users")

      assert conn.status == 200
    end

    test "returns JSON content type", %{conn: conn} do
      conn = get(conn, ~p"/api/users")

      assert List.keyfind(conn.resp_headers, "content-type", 0) ==
               {"content-type", "application/json; charset=utf-8"}
    end
  end

  describe "POST /api/users (create)" do
    test "creates user with valid attributes", %{conn: conn} do
      conn = post(conn, ~p"/api/users", %{name: "New User"})

      assert %{"data" => user_data} = json_response(conn, 201)
      assert user_data["name"] == "New User"
      assert user_data["id"]
    end

    test "returns 201 status code on success", %{conn: conn} do
      conn = post(conn, ~p"/api/users", %{name: "New User"})

      assert conn.status == 201
    end

    test "returns JSON content type", %{conn: conn} do
      conn = post(conn, ~p"/api/users", %{name: "New User"})

      assert List.keyfind(conn.resp_headers, "content-type", 0) ==
               {"content-type", "application/json; charset=utf-8"}
    end

    test "returns 422 when name is missing", %{conn: conn} do
      conn = post(conn, ~p"/api/users", %{})

      response = json_response(conn, 422)
      assert response["errors"]["name"]
    end

    test "returns 422 when name is empty", %{conn: conn} do
      conn = post(conn, ~p"/api/users", %{name: ""})

      response = json_response(conn, 422)
      assert response["errors"]["name"]
    end
  end
end
