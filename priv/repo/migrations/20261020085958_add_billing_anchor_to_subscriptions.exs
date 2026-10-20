defmodule Subtrack.Repo.Migrations.AddBillingAnchorToSubscriptions do
  use Ecto.Migration

  def up do
    alter table(:subscriptions) do
      add :billing_anchor_on, :date
    end

    # Existing rows: their current renewal date is the best anchor we have.
    execute "UPDATE subscriptions SET billing_anchor_on = next_renewal_on"

    alter table(:subscriptions) do
      modify :billing_anchor_on, :date, null: false
    end
  end

  def down do
    alter table(:subscriptions) do
      remove :billing_anchor_on
    end
  end
end
