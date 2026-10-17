defmodule Subtrack.Repo.Migrations.CreateReminders do
  use Ecto.Migration

  def change do
    create table(:reminders, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :days_before, :integer, null: false
      add :send_at, :time, null: false
      add :channels, {:array, :string}, null: false
      add :enabled, :boolean, default: false, null: false

      add :subscription_id, references(:subscriptions, on_delete: :delete_all, type: :binary_id),
        null: false

      add :user_id, references(:users, type: :binary_id, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:reminders, [:user_id])
    create unique_index(:reminders, [:subscription_id, :days_before, :send_at])

    create constraint(:reminders, :days_before_range, check: "days_before BETWEEN 0 AND 90")
    create constraint(:reminders, :channels_not_empty, check: "cardinality(channels) > 0")
  end
end
