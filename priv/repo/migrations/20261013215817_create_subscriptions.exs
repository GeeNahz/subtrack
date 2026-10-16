defmodule Subtrack.Repo.Migrations.CreateSubscriptions do
  use Ecto.Migration

  def change do
    create table(:subscriptions, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string, null: false
      add :plan_name, :string
      add :amount, :decimal, precision: 14, scale: 2, null: false
      add :fee_amount, :decimal, precision: 14, scale: 2, null: false, default: 0
      add :currency, :string, size: 3, null: false
      add :fx_rate, :decimal, precision: 18, scale: 6
      add :billing_cycle, :string, null: false
      add :next_renewal_on, :date, null: false
      add :status, :string, null: false, default: "active"
      add :manage_url, :string
      add :notes, :text

      add :payment_method_id,
          references(:payment_methods, on_delete: :nilify_all, type: :binary_id)

      add :user_id, references(:users, type: :binary_id, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:subscriptions, [:user_id])
    create index(:subscriptions, [:payment_method_id])
    create index(:subscriptions, [:status, :next_renewal_on])

    create constraint(:subscriptions, :amount_positive, check: "amount > 0")
    create constraint(:subscriptions, :fee_non_negative, check: "fee_amount >= 0")
    create constraint(:subscriptions, :fx_rate_positive, check: "fx_rate IS NULL OR fx_rate > 0")
  end
end
