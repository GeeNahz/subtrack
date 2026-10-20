defmodule Subtrack.Notifications do
  import Ecto.Query, warn: false

  alias Subtrack.Repo
  alias Subtrack.Accounts.User
  alias Subtrack.Notifications.{ReminderDelivery, Schedule}
  alias Subtrack.Subscriptions.{Reminder, Subscription}
  alias Subtrack.Workers.SendReminder

  # --- Finding what is due ------------

  @doc """
  Claims and enqueues every due delivery. Returns how many were newly enqueued.
  """
  def enqueue_due(now \\ DateTime.utc_now()) do
    now
    |> candidates()
    |> Enum.flat_map(&due_deliveries(&1, now))
    |> Enum.map(fn {reminder, renewal_on, channel} ->
      claim_and_enqueue(reminder, renewal_on, channel)
    end)
    |> Enum.count(&(&1 == {:ok, :enqueued}))
  end

  # Coarse filter in SQL: only reminders whose "reminder date"
  # (renewal date minus days_before) is within 2 days of today (UTC).
  # Timezones shift the real moment by at most about a day, so the window is safe.
  defp candidates(now) do
    today = DateTime.to_date(now)
    earliest = Date.add(today, -2)
    latest = Date.add(today, 2)

    from(r in Reminder,
      join: s in Subscription,
      on: s.id == r.subscription_id,
      join: u in User,
      on: u.id == s.user_id,
      where: r.enabled and s.status == :active,
      where: fragment("? - ?", s.next_renewal_on, r.days_before) >= ^earliest,
      where: fragment("? - ?", s.next_renewal_on, r.days_before) <= ^latest,
      select: {r, s, u}
    )
    |> Repo.all()
  end

  # Precise check in Elixir: exact due moment, per reminder.
  defp due_deliveries({reminder, subscription, user}, now) do
    with {:ok, due_at} <-
           Schedule.due_at(
             subscription.next_renewal_on,
             reminder.days_before,
             reminder.send_at,
             user.timezone
           ),
         :due <- Schedule.state(due_at, now) do
      Enum.map(reminder.channels, &{reminder, subscription.next_renewal_on, &1})
    else
      _upcoming_expired_or_error -> []
    end
  end

  # --- Claiming ------------

  @doc """
  Records the delivery and enqueues its job, atomically.
  Returns {:ok, :enqueued} or {:ok, :already_claimed}.
  """
  def claim_and_enqueue(%Reminder{} = reminder, %Date{} = renewal_on, channel) do
    now = DateTime.utc_now(:second)

    row = %{
      id: Ecto.UUID.generate(),
      reminder_id: reminder.id,
      renewal_on: renewal_on,
      channel: channel,
      status: :pending,
      inserted_at: now,
      updated_at: now
    }

    Repo.transaction(fn ->
      case Repo.insert_all(ReminderDelivery, [row],
             on_conflict: :nothing,
             conflict_target: [:reminder_id, :renewal_on, :channel],
             returning: [:id]
           ) do
        {1, [delivery]} ->
          {:ok, _job} = Oban.insert(SendReminder.new(%{delivery_id: delivery.id}))
          :enqueued

        {0, _} ->
          :already_claimed
      end
    end)
  end

  # --- Delivery bookkeeping ------------

  def get_delivery(id) do
    ReminderDelivery
    |> Repo.get(id)
    |> Repo.preload(reminder: [subscription: :payment_method])
  end

  def mark_sent(%ReminderDelivery{} = delivery, provider_ref) do
    delivery
    |> Ecto.Changeset.change(
      status: :sent,
      provider_ref: provider_ref,
      sent_at: DateTime.utc_now(:second),
      error: nil
    )
    |> Repo.update()
  end

  def mark_skipped(%ReminderDelivery{} = delivery, reason) do
    delivery
    |> Ecto.Changeset.change(status: :skipped, error: reason)
    |> Repo.update()
  end

  def record_failure(%ReminderDelivery{} = delivery, reason, final? \\ false) do
    changes = [error: reason |> inspect() |> String.slice(0, 500)]
    changes = if final?, do: Keyword.put(changes, :status, :failed), else: changes

    delivery |> Ecto.Changeset.change(changes) |> Repo.update()
  end
end
