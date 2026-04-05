defmodule ApiTokenPool.Tokens.Token do
  use Ecto.Schema
  import Ecto.Changeset

  alias ApiTokenPool.Accounts.User

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "tokens" do
    field :allocated_at, :utc_datetime

    belongs_to :user, User

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(token, attrs) do
    cast(token, attrs, [:allocated_at])
  end

  def allocate_changeset(token, attrs) do
    token
    |> cast(attrs, [:user_id, :allocated_at])
    |> validate_required([:user_id, :allocated_at])
  end

  def release_changeset(token) do
    change(token, %{user_id: nil, allocated_at: nil})
  end
end
