defmodule ApiTokenPool.Tokens.Token do
  use Ecto.Schema
  import Ecto.Changeset

  alias ApiTokenPool.Accounts.User

  @valid_statuses ~w(available allocated)a

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "tokens" do
    field :allocated_at, :utc_datetime
    field :status, Ecto.Enum, values: [:available, :allocated], default: :available

    belongs_to :user, User

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(token, attrs) do
    token
    |> cast(attrs, [:allocated_at, :status])
    |> validate_inclusion(:status, @valid_statuses)
  end

  def allocate_changeset(token, attrs) do
    token
    |> cast(attrs, [:user_id, :allocated_at])
    |> validate_required([:user_id, :allocated_at])
    |> put_change(:status, :allocated)
  end

  def release_changeset(token) do
    change(token, %{user_id: nil, allocated_at: nil, status: :available})
  end

  def valid_statuses, do: @valid_statuses
end
