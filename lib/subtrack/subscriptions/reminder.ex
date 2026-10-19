defmodule Subtrack.Subscriptions.Reminder do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "reminders" do
    field :days_before, :integer
    field :send_at, :time, default: ~T[09:00:00]

    field :channels, {:array, Ecto.Enum},
      values: Subtrack.Notifications.Channels.all(),
      default: [:email]

    field :enabled, :boolean, default: true
    field :user_id, :binary_id
    field :note, :string

    belongs_to :subscription, Subtrack.Subscriptions.Subscription

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(reminder, attrs, user_scope) do
    reminder
    |> cast(attrs, [:days_before, :send_at, :channels, :enabled, :note])
    |> validate_required([:days_before, :send_at, :channels])
    |> validate_number(:days_before, greater_than_or_equal_to: 0, less_than_or_equal_to: 90)
    |> validate_length(:channels, min: 1)
    |> validate_length(:note, max: 200)
    |> update_change(:channels, &Enum.uniq/1)
    |> unique_constraint([:subscription_id, :days_before, :send_at],
      error_key: :days_before,
      message: "you already have a reminder at that time"
    )
    |> put_change(:user_id, user_scope.user.id)
  end
end
