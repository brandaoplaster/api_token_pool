defmodule ApiTokenPool.Tokens.UsageHistory do
  use Ecto.Schema
  import Ecto.Changeset

  alias ApiTokenPool.Accounts.User
  alias ApiTokenPool.Tokens.Token

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "token_usage_history" do
    field :started_at, :utc_datetime
    field :ended_at, :utc_datetime

    belongs_to :token, Token
    belongs_to :user, User

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(usage_history, attrs) do
    usage_history
    |> cast(attrs, [:started_at, :token_id, :user_id])
    |> validate_required([:started_at, :token_id, :user_id])
  end

  def close_changeset(usage_history) do
    ended_at = DateTime.truncate(DateTime.utc_now(), :second)
    change(usage_history, %{ended_at: ended_at})
  end
end
