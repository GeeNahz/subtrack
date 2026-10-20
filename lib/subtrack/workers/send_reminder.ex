defmodule Subtrack.Workers.SendReminder do
  use Oban.Worker, queue: :notifications, max_attempts: 5

  alias Subtrack.{Accounts, Notifications}
  alias Subtrack.Notifications.Dispatcher

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"delivery_id" => id}} = job) do
    case Notifications.get_delivery(id) do
      nil -> {:cancel, "delivery no longer exists"}
      %{status: :pending} = delivery -> delivery(delivery, job)
      _already_handled -> :ok
    end
  end

  defp delivery(delivery, job) do
    %{reminder: %{subscription: subscription} = reminder} = delivery

    if skip?(delivery, reminder, subscription) do
      Notifications.mark_skipped(delivery, "reminder or subscription changed")
      :ok
    else
      user = Accounts.get_user_with_profile!(subscription.user_id)

      case Dispatcher.deliver(delivery.channel, reminder, subscription, user) do
        {:ok, provider_ref} ->
          Notifications.mark_sent(delivery, provider_ref)
          :ok

        {:permanent, reason} ->
          Notifications.record_failure(delivery, reason, true)
          {:cancel, reason}

        {:error, reason} ->
          final? = job.attempt >= job.max_attempts
          Notifications.record_failure(delivery, reason, final?)
          {:error, reason}
      end
    end
  end

  # The world may have changed between "claimed" and "running".
  defp skip?(delivery, reminder, subscription) do
    not reminder.enabled or subscription.status != :active or
      subscription.next_renewal_on != delivery.renewal_on
  end
end
