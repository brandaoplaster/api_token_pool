defmodule ApiTokenPoolWeb.FallbackController do
  use ApiTokenPoolWeb, :controller

  def call(conn, {:error, :not_found}) do
    conn
    |> put_status(:not_found)
    |> json(%{error: "not found"})
  end

  def call(conn, {:error, :invalid_uuid}) do
    conn
    |> put_status(:bad_request)
    |> json(%{error: "invalid uuid format"})
  end

  def call(conn, {:error, :no_tokens_available}) do
    conn
    |> put_status(:unprocessable_entity)
    |> json(%{error: "no tokens available"})
  end

  def call(conn, {:error, %Ecto.Changeset{} = changeset}) do
    conn
    |> put_status(:unprocessable_entity)
    |> json(%{errors: translate_errors(changeset)})
  end

  def call(conn, {:error, reason}) do
    conn
    |> put_status(:unprocessable_entity)
    |> json(%{error: reason})
  end

  defp translate_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Regex.replace(~r"%{(\w+)}", msg, fn _, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
  end
end
