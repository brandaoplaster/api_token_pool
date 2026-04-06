defmodule ApiTokenPoolWeb.UserController do
  use ApiTokenPoolWeb, :controller

  alias ApiTokenPool.UseCases.{CreateUser, ListUsers}

  action_fallback ApiTokenPoolWeb.FallbackController

  def index(conn, _params) do
    users = ListUsers.execute()
    render(conn, :index, users: users)
  end

  def create(conn, params) do
    with {:ok, user} <- CreateUser.execute(params) do
      conn
      |> put_status(:created)
      |> render(:show, user: user)
    end
  end
end
