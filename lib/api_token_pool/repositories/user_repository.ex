defmodule ApiTokenPool.Repositories.UserRepository do
  import Ecto.Query, warn: false

  alias ApiTokenPool.Accounts.User
  alias ApiTokenPool.Repo

  def list_all do
    Repo.all(User)
  end

  def get(id) do
    Repo.get(User, id)
  end

  def create(attrs) do
    %User{}
    |> User.changeset(attrs)
    |> Repo.insert()
  end
end
