defmodule ApiTokenPoolWeb.TokenControllerTest do
  use ApiTokenPoolWeb.ConnCase, async: true
  import ApiTokenPool.Factory

  describe "GET /api/tokens (index)" do
    test "returns empty list when no tokens exist", %{conn: conn} do
      conn = get(conn, ~p"/api/tokens")

      assert json_response(conn, 200) == %{"data" => []}
    end

    test "returns all tokens when multiple exist", %{conn: conn} do
      token1 = insert(:token)
      token2 = insert(:token)

      conn = get(conn, ~p"/api/tokens")

      response = json_response(conn, 200)
      assert length(response["data"]) == 2

      token_ids = Enum.map(response["data"], & &1["id"])
      assert token1.id in token_ids
      assert token2.id in token_ids
    end

    test "returns tokens with correct structure", %{conn: conn} do
      token = insert(:token)

      conn = get(conn, ~p"/api/tokens")

      assert %{"data" => [token_data]} = json_response(conn, 200)
      assert token_data["id"] == token.id
      assert token_data["status"] == "available"
      assert is_nil(token_data["user_id"])
      assert is_nil(token_data["allocated_at"])
    end

    test "returns available tokens", %{conn: conn} do
      insert(:token)
      insert(:token)

      conn = get(conn, ~p"/api/tokens")

      response = json_response(conn, 200)
      assert length(response["data"]) == 2
      assert Enum.all?(response["data"], fn t -> t["status"] == "available" end)
    end

    test "returns allocated tokens", %{conn: conn} do
      insert(:allocated_token)

      conn = get(conn, ~p"/api/tokens")

      response = json_response(conn, 200)
      assert [token_data] = response["data"]
      assert token_data["status"] == "allocated"
      refute is_nil(token_data["user_id"])
      refute is_nil(token_data["allocated_at"])
    end

    test "returns mixed status tokens", %{conn: conn} do
      insert(:token)
      insert(:allocated_token)

      conn = get(conn, ~p"/api/tokens")

      response = json_response(conn, 200)
      assert length(response["data"]) == 2

      statuses = Enum.map(response["data"], & &1["status"])
      assert "available" in statuses
      assert "allocated" in statuses
    end

    test "returns large number of tokens", %{conn: conn} do
      Enum.each(1..50, fn _ -> insert(:token) end)

      conn = get(conn, ~p"/api/tokens")

      response = json_response(conn, 200)
      assert length(response["data"]) == 50
    end

    test "returns 200 status code", %{conn: conn} do
      insert(:token)

      conn = get(conn, ~p"/api/tokens")

      assert conn.status == 200
    end

    test "returns JSON content type", %{conn: conn} do
      conn = get(conn, ~p"/api/tokens")

      assert List.keyfind(conn.resp_headers, "content-type", 0) ==
               {"content-type", "application/json; charset=utf-8"}
    end
  end

  describe "GET /api/tokens/:id (show)" do
    test "returns token when valid id is provided", %{conn: conn} do
      token = insert(:token)

      conn = get(conn, ~p"/api/tokens/#{token.id}")

      assert %{"data" => token_data} = json_response(conn, 200)
      assert token_data["id"] == token.id
      assert token_data["status"] == "available"
    end

    test "returns available token with correct attributes", %{conn: conn} do
      token = insert(:token)

      conn = get(conn, ~p"/api/tokens/#{token.id}")

      assert %{"data" => token_data} = json_response(conn, 200)
      assert token_data["id"] == token.id
      assert token_data["status"] == "available"
      assert is_nil(token_data["user_id"])
      assert is_nil(token_data["allocated_at"])
    end

    test "returns allocated token with correct attributes", %{conn: conn} do
      token = insert(:allocated_token)

      conn = get(conn, ~p"/api/tokens/#{token.id}")

      assert %{"data" => token_data} = json_response(conn, 200)
      assert token_data["id"] == token.id
      assert token_data["status"] == "allocated"
      refute is_nil(token_data["user_id"])
      refute is_nil(token_data["allocated_at"])
    end

    test "returns 200 status code for existing token", %{conn: conn} do
      token = insert(:token)

      conn = get(conn, ~p"/api/tokens/#{token.id}")

      assert conn.status == 200
    end

    test "returns JSON content type", %{conn: conn} do
      token = insert(:token)

      conn = get(conn, ~p"/api/tokens/#{token.id}")

      assert List.keyfind(conn.resp_headers, "content-type", 0) ==
               {"content-type", "application/json; charset=utf-8"}
    end

    test "returns 400 for invalid UUID format", %{conn: conn} do
      conn = get(conn, ~p"/api/tokens/invalid-uuid")
      assert json_response(conn, 400) == %{"error" => "invalid uuid format"}
    end

    test "returns 404 when token does not exist", %{conn: conn} do
      non_existent_id = Ecto.UUID.generate()

      conn = get(conn, ~p"/api/tokens/#{non_existent_id}")

      assert json_response(conn, 404) == %{"error" => "not found"}
    end

    test "returns 404 status code for non-existent token", %{conn: conn} do
      non_existent_id = Ecto.UUID.generate()

      conn = get(conn, ~p"/api/tokens/#{non_existent_id}")

      assert conn.status == 404
    end

    test "returns error message for multiple non-existent tokens", %{conn: conn} do
      id1 = Ecto.UUID.generate()
      id2 = Ecto.UUID.generate()

      conn1 = get(conn, ~p"/api/tokens/#{id1}")
      conn2 = get(conn, ~p"/api/tokens/#{id2}")

      assert json_response(conn1, 404) == %{"error" => "not found"}
      assert json_response(conn2, 404) == %{"error" => "not found"}
    end
  end

  describe "integration scenarios" do
    test "index shows token that was just created", %{conn: conn} do
      token = insert(:token)

      conn = get(conn, ~p"/api/tokens")

      response = json_response(conn, 200)
      token_ids = Enum.map(response["data"], & &1["id"])
      assert token.id in token_ids
    end

    test "show returns same token as appears in index", %{conn: conn} do
      token = insert(:token)

      conn_index = get(conn, ~p"/api/tokens")
      conn_show = get(conn, ~p"/api/tokens/#{token.id}")

      index_response = json_response(conn_index, 200)
      show_response = json_response(conn_show, 200)

      [index_token] = index_response["data"]
      show_token = show_response["data"]

      assert index_token["id"] == show_token["id"]
      assert index_token["status"] == show_token["status"]
    end

    test "multiple sequential requests return consistent results", %{conn: conn} do
      token = insert(:token)

      conn1 = get(conn, ~p"/api/tokens/#{token.id}")
      conn2 = get(conn, ~p"/api/tokens/#{token.id}")
      conn3 = get(conn, ~p"/api/tokens/#{token.id}")

      response1 = json_response(conn1, 200)
      response2 = json_response(conn2, 200)
      response3 = json_response(conn3, 200)

      assert response1 == response2
      assert response2 == response3
    end
  end

  describe "POST /api/tokens/allocate (allocate)" do
    test "allocates token successfully with valid user_id", %{conn: conn} do
      insert(:token)
      user = insert(:user)

      conn = post(conn, ~p"/api/tokens/allocate", %{user_id: user.id})

      assert %{"data" => token_data} = json_response(conn, 201)
      assert token_data["token_id"]
      assert token_data["user_id"] == user.id
    end

    test "returns 201 status code on success", %{conn: conn} do
      insert(:token)
      user = insert(:user)

      conn = post(conn, ~p"/api/tokens/allocate", %{user_id: user.id})

      assert conn.status == 201
    end

    test "returns JSON content type", %{conn: conn} do
      insert(:token)
      user = insert(:user)

      conn = post(conn, ~p"/api/tokens/allocate", %{user_id: user.id})

      assert List.keyfind(conn.resp_headers, "content-type", 0) ==
               {"content-type", "application/json; charset=utf-8"}
    end

    test "allocates to different users sequentially", %{conn: conn} do
      insert(:token)
      insert(:token)
      user1 = insert(:user)
      user2 = insert(:user)

      conn1 = post(conn, ~p"/api/tokens/allocate", %{user_id: user1.id})
      conn2 = post(conn, ~p"/api/tokens/allocate", %{user_id: user2.id})

      response1 = json_response(conn1, 201)
      response2 = json_response(conn2, 201)

      assert response1["data"]["user_id"] == user1.id
      assert response2["data"]["user_id"] == user2.id
    end

    test "releases oldest token when no available tokens", %{conn: conn} do
      insert(:token)
      user1 = insert(:user)
      user2 = insert(:user)

      post(conn, ~p"/api/tokens/allocate", %{user_id: user1.id})
      conn = post(conn, ~p"/api/tokens/allocate", %{user_id: user2.id})

      assert %{"data" => token_data} = json_response(conn, 201)
      assert token_data["user_id"] == user2.id
    end

    test "returns 400 for invalid user_id format", %{conn: conn} do
      insert(:token)

      conn = post(conn, ~p"/api/tokens/allocate", %{user_id: "invalid-uuid"})

      assert json_response(conn, 400) == %{"error" => "invalid uuid format"}
    end

    test "returns 400 when user_id is missing", %{conn: conn} do
      insert(:token)

      conn = post(conn, ~p"/api/tokens/allocate", %{})

      assert conn.status == 400
    end

    test "returns 422 when no tokens exist", %{conn: conn} do
      user = insert(:user)

      conn = post(conn, ~p"/api/tokens/allocate", %{user_id: user.id})

      assert json_response(conn, 422) == %{"error" => "no tokens available"}
    end

    test "returns 422 status code when pool is empty", %{conn: conn} do
      user = insert(:user)

      conn = post(conn, ~p"/api/tokens/allocate", %{user_id: user.id})

      assert conn.status == 422
    end
  end

  describe "POST /api/tokens/release-active (release_active)" do
    defp create_allocated_token_with_history do
      token = insert(:allocated_token)
      insert(:usage_history, token: token, ended_at: nil)
      token
    end

    test "releases all allocated tokens successfully", %{conn: conn} do
      create_allocated_token_with_history()
      create_allocated_token_with_history()

      conn = post(conn, ~p"/api/tokens/release-active")

      assert %{"data" => %{"released" => 2}} = json_response(conn, 200)
    end

    test "returns count of released tokens", %{conn: conn} do
      create_allocated_token_with_history()
      create_allocated_token_with_history()
      create_allocated_token_with_history()

      conn = post(conn, ~p"/api/tokens/release-active")

      assert %{"data" => data} = json_response(conn, 200)
      assert data["released"] == 3
    end

    test "returns 0 when no allocated tokens exist", %{conn: conn} do
      insert(:token)
      insert(:token)

      conn = post(conn, ~p"/api/tokens/release-active")

      assert %{"data" => %{"released" => 0}} = json_response(conn, 200)
    end

    test "returns 0 when no tokens exist", %{conn: conn} do
      conn = post(conn, ~p"/api/tokens/release-active")

      assert %{"data" => %{"released" => 0}} = json_response(conn, 200)
    end

    test "returns 200 status code", %{conn: conn} do
      create_allocated_token_with_history()

      conn = post(conn, ~p"/api/tokens/release-active")

      assert conn.status == 200
    end

    test "returns JSON content type", %{conn: conn} do
      conn = post(conn, ~p"/api/tokens/release-active")

      assert List.keyfind(conn.resp_headers, "content-type", 0) ==
               {"content-type", "application/json; charset=utf-8"}
    end

    test "ignores available tokens", %{conn: conn} do
      insert(:token)
      create_allocated_token_with_history()

      conn = post(conn, ~p"/api/tokens/release-active")

      assert %{"data" => %{"released" => 1}} = json_response(conn, 200)
    end

    test "tokens become available after release", %{conn: conn} do
      create_allocated_token_with_history()
      create_allocated_token_with_history()

      post(conn, ~p"/api/tokens/release-active")

      conn = get(conn, ~p"/api/tokens")
      response = json_response(conn, 200)

      tokens = response["data"]
      assert length(tokens) == 2
      assert Enum.all?(tokens, fn t -> t["status"] == "available" end)
    end
  end
end
