defmodule ApiTokenPool.Repo.Migrations.CreateTokenUsageHistory do
  use Ecto.Migration

  def change do
    create table(:token_usage_history, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :started_at, :utc_datetime, null: false
      add :ended_at, :utc_datetime
      add :token_id, references(:tokens, on_delete: :nothing, type: :binary_id), null: false
      add :user_id, references(:users, on_delete: :nothing, type: :binary_id), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:token_usage_history, [:token_id])
    create index(:token_usage_history, [:token_id, :ended_at])
  end
end
