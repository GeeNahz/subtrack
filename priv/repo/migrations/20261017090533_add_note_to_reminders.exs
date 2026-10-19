defmodule Subtrack.Repo.Migrations.AddNoteToReminders do
  use Ecto.Migration

  def change do
    alter table(:reminders) do
      add :note, :string, text: 200
    end
  end
end
