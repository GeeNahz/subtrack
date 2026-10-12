defmodule Subtrack.Repo.Migrations.AddContactFieldsToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :phone_number, :string
      add :phone_confirmed_at, :utc_datetime
      add :timezone, :string, null: false, default: "Etc/UTC"
    end

    create unique_index(:users, [:phone_number])
  end
end
