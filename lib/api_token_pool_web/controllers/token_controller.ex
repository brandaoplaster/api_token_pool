defmodule ApiTokenPoolWeb.TokenController do
  use ApiTokenPoolWeb, :controller

  alias ApiTokenPool.UseCases.GetToken
  alias ApiTokenPool.UseCases.ListTokens

  action_fallback ApiTokenPoolWeb.FallbackController

  def index(conn, _params) do
    tokens = ListTokens.execute()
    render(conn, :index, tokens: tokens)
  end

  def show(conn, %{"id" => id}) do
    with {:ok, token} <- GetToken.execute(id) do
      render(conn, :show, token: token)
    end
  end
end
