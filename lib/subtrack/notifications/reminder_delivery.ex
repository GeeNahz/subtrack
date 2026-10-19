defmodule Subtrack.Notifications.ReminderDelivery do
  use Ecto.Schema

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "reminder_deliveries" do
    field :renewal_on, :date
    field :channel, Ecto.Enum, values: Subtrack.Notifications.Channels.all()
    field :status, Ecto.Enum, values: [:pending, :sent, :failed, :skipped], default: :pending
    field :provider_ref, :string
    field :error, :string
    field :sent_at, :utc_datetime

    belongs_to :reminder, Subtrack.Subscriptions.Reminder

    timestamps(type: :utc_datetime)
  end
end
