defmodule ApiTokenPoolWeb.UserJSON do
  def index(%{users: users}), do: %{data: Enum.map(users, &data/1)}
  def show(%{user: user}), do: %{data: data(user)}

  defp data(user) do
    %{
      id: user.id,
      name: user.name,
      inserted_at: user.inserted_at,
      updated_at: user.updated_at
    }
  end
end
