defmodule Subtrack.Repo.Migrations.CreateReminderDeliveries do
  use Ecto.Migration

  def change do
    create table(:reminder_deliveries, primary_key: false) do
      add :id, :binary_id, primary_key: true

      add :reminder_id, references(:reminders, type: :binary_id, on_delete: :delete_all),
        null: false

      add :renewal_on, :date, null: false
      add :channel, :string, null: false
      add :status, :string, null: false, default: "pending"
      add :provider_ref, :string
      add :error, :text
      add :sent_at, :utc_datetime

      timestamps(type: :utc_datetime)
    end

    create unique_index(:reminder_deliveries, [:reminder_id, :renewal_on, :channel])
    create index(:reminder_deliveries, [:status])
  end
end
