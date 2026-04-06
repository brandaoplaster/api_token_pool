defmodule ApiTokenPoolWeb.TokenController do
  use ApiTokenPoolWeb, :controller

  alias ApiTokenPool.UseCases.AllocateToken
  alias ApiTokenPool.UseCases.GetToken
  alias ApiTokenPool.UseCases.ListTokens

  action_fallback ApiTokenPoolWeb.FallbackController

  def allocate(conn, params) do
    case Map.get(params, "user_id") do
      nil ->
        conn
        |> put_status(:bad_request)
        |> json(%{error: "user_id is required"})

      user_id ->
        with {:ok, token} <- AllocateToken.execute(user_id) do
          conn
          |> put_status(:created)
          |> render(:allocate, token: token)
        end
    end
  end

  def index(conn, _params) do
    tokens = ListTokens.execute()
    render(conn, :index, tokens: tokens)
  end

  def show(conn, %{"id" => id}) do
    with {:ok, token} <- GetToken.execute(id) do
      render(conn, :show, token: token)
    end
  end

  def history(conn, %{"id" => id}) do
    with {:ok, history} <- GetToken.execute_history(id) do
      render(conn, :history, history: history)
    end
  end
end
