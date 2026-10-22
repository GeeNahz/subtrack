defmodule Subtrack.Notifications.ReminderSms do
  alias Subtrack.Money
  alias Subtrack.Notifications.ReminderEmail
  alias Subtrack.Subscriptions.Subscription

  def build(reminder, subscription) do
    date = Calendar.strftime(subscription.next_renewal_on, "%d %b")
    amount = Money.format(Subscription.total_amount(subscription), subscription.currency)

    base =
      "Subtrack: #{subscription.name} #{ReminderEmail.when_text(reminder.days_before)} (#{date}), #{amount}."

    case note(reminder) do
      nil -> base
      text -> base <> " Note: " <> text
    end
  end

  defp note(%{note: note}) when is_binary(note) do
    case String.trim(note) do
      "" -> nil
      text -> text
    end
  end

  defp note(_), do: nil
end
