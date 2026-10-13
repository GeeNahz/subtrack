defmodule Subtrack.Repo.Migrations.CreatePaymentMethods do
  use Ecto.Migration

  def change do
    create table(:payment_methods, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :nickname, :string
      add :brand, :string, null: false
      add :card_mode, :string, null: false
      add :currency, :string, null: false, size: 3
      add :last4, :string, null: false, size: 4
      add :bank_name, :string
      add :expiry_month, :integer
      add :expiry_year, :integer
      add :user_id, references(:users, type: :binary_id, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:payment_methods, [:user_id])

    create constraint(:payment_methods, :expiry_month_range,
             check: "expiry_month IS NULL OR expiry_month BETWEEN 1 AND 12"
           )
  end
end
