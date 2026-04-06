defmodule ApiTokenPool.Repo.Migrations.CreateTokens do
  use Ecto.Migration

  def up do
    execute """
    CREATE TYPE token_status AS ENUM ('available', 'allocated', 'blocked')
    """

    create table(:tokens, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :allocated_at, :utc_datetime
      add :status, :token_status, default: "available", null: false
      add :user_id, references(:users, on_delete: :nothing, type: :binary_id)

      timestamps(type: :utc_datetime)
    end

    create index(:tokens, [:user_id])
    create index(:tokens, [:status])
  end

  def down do
    drop table(:tokens)
    execute "DROP TYPE token_status"
  end
end
