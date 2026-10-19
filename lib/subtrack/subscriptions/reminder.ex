defmodule Subtrack.Subscriptions.Reminder do
  use Ecto.Schema
  import Ecto.Changeset

  @max_days_before 90
  @max_note_length 200

  def max_days_before, do: @max_days_before
  def max_note_length, do: @max_note_length

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
    |> validate_number(:days_before,
      greater_than_or_equal_to: 0,
      less_than_or_equal_to: @max_days_before
    )
    |> validate_length(:channels, min: 1)
    |> validate_length(:note, max: @max_note_length)
    |> update_change(:channels, &Enum.uniq/1)
    |> unique_constraint([:subscription_id, :days_before, :send_at],
      error_key: :days_before,
      message: "you already have a reminder at that time"
    )
    |> put_change(:user_id, user_scope.user.id)
  end
end
