defmodule ApiTokenPoolWeb.FallbackController do
  use ApiTokenPoolWeb, :controller

  def call(conn, {:error, :not_found}) do
    conn
    |> put_status(:not_found)
    |> json(%{error: "not found"})
  end

  def call(conn, {:error, :no_tokens_available}) do
    conn
    |> put_status(:unprocessable_entity)
    |> json(%{error: "no tokens available"})
  end

  def call(conn, {:error, reason}) do
    conn
    |> put_status(:unprocessable_entity)
    |> json(%{error: reason})
  end
end
