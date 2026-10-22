defmodule Subtrack.Repo.Migrations.PhoneVerification do
  use Ecto.Migration

  def change do
    # Uniqueness now applies only to numbers someone has proven to own.
    drop unique_index(:users, [:phone_number])

    create unique_index(:users, [:phone_number],
             where: "phone_confirmed_at IS NOT NULL",
             name: :users_verified_phone_number_index
           )

    create table(:phone_verifications, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :user_id, references(:users, type: :binary_id, on_delete: :delete_all), null: false
      add :phone_number, :string, null: false
      add :code_hash, :string, null: false
      add :attempts, :integer, null: false, default: 0
      add :expires_at, :utc_datetime, null: false
      add :sent_at, :utc_datetime, null: false

      timestamps(type: :utc_datetime)
    end

    # One pending code per user: sending a new one replaces the old one.
    create unique_index(:phone_verifications, [:user_id])
  end
end
