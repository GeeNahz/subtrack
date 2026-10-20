defmodule Subtrack.NotificationsTest do
  use Subtrack.DataCase
  use Oban.Testing, repo: Subtrack.Repo

  import Subtrack.AccountsFixtures
  import Subtrack.SubscriptionsFixtures

  alias Subtrack.Notifications
  alias Subtrack.Workers.SendReminder

  # Reminder due 2026-11-05 09:00 UTC (renewal 11-10, 5 days before)
  setup do
    scope = user_scope_fixture()
    subscription = subscription_fixture(scope, %{next_renewal_on: ~D[2026-11-10]})

    reminder =
      reminder_fixture(scope, %{
        subscription: subscription,
        days_before: 5,
        send_at: ~T[09:00:00],
        channels: [:email]
      })

    %{reminder: reminder}
  end

  test "enqueues once when due, and never twice" do
    now = ~U[2026-11-05 09:10:00Z]

    assert Notifications.enqueue_due(now) == 1
    assert Notifications.enqueue_due(now) == 0
    assert [_one_job] = all_enqueued(worker: SendReminder)
  end

  test "does not enqueue before the due date" do
    assert Notifications.enqueue_due(~U[2026-11-05 08:50:00Z]) == 0
  end

  test "does not enqueue after grace window" do
    assert Notifications.enqueue_due(~U[2026-11-05 16:00:00Z]) == 0
  end

  test "the worker marks the delivery sent" do
    Notifications.enqueue_due(~U[2026-11-05 09:10:00Z])
    [job] = all_enqueued(worker: SendReminder)

    assert :ok = perform_job(SendReminder, job.args)
    assert Notifications.get_delivery(job.args["delivery_id"]).status == :sent
    assert_received {:email, %Swoosh.Email{subject: "some name renews in 5 days"} = email}
    assert email.text_body =~ "Amount: GBP 241.00"
  end

  test "the worker skips a reminder disabled after it was claimed", %{reminder: reminder} do
    Notifications.enqueue_due(~U[2026-11-05 09:10:00Z])
    [job] = all_enqueued(worker: SendReminder)

    reminder |> Ecto.Changeset.change(enabled: false) |> Repo.update!()

    assert :ok = perform_job(SendReminder, job.args)
    assert Notifications.get_delivery(job.args["delivery_id"]).status == :skipped
  end
end
