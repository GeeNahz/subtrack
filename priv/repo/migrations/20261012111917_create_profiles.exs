defmodule Subtrack.Repo.Migrations.CreateProfiles do
  use Ecto.Migration

  def change do
    create table(:profiles, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :user_id, references(:users, type: :binary_id, on_delete: :delete_all), null: false
      add :first_name, :string, null: false
      add :last_name, :string
      add :username, :citext

      timestamps(type: :utc_datetime)
    end

    create unique_index(:profiles, [:user_id])
    create unique_index(:profiles, [:username])
  end
end
