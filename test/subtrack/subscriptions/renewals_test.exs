defmodule Subtrack.Subscriptions.RenewalsTest do
  use Subtrack.DataCase

  import Subtrack.AccountsFixtures
  import Subtrack.SubscriptionsFixtures

  alias Subtrack.Subscriptions
  alias Subtrack.Subscriptions.{Renewals, Subscription}

  describe "decide/2" do
    test "waits until local date is more than one day past the renewal" do
      sub = %Subscription{
        next_renewal_on: ~D[2026-03-14],
        billing_anchor_on: ~D[2026-03-14],
        billing_cycle: :monthly
      }

      assert Renewals.decide(sub, ~D[2026-03-14]) == :keep
      assert Renewals.decide(sub, ~D[2026-03-15]) == :keep
      assert Renewals.decide(sub, ~D[2026-03-16]) == {:roll, ~D[2026-04-14]}
    end
  end

  describe "Local_today/2" do
    test "uses the user's timezone, and falls back to UTC for a bad one" do
      now = ~U[2026-03-15 23:30:00Z]
      assert Renewals.local_today(now, "Africa/Lagos") == ~D[2026-03-16]
      assert Renewals.local_today(now, "Nope/Nowhere") == ~D[2026-03-15]
    end
  end

  describe "roll_due/1" do
    test "rolls past renewals using the anchor, leaves future ones, and is idempotent" do
      scope = user_scope_fixture()

      past =
        subscription_fixture(scope, %{next_renewal_on: ~D[2026-01-31], billing_cycle: :monthly})

      future =
        subscription_fixture(scope, %{next_renewal_on: ~D[2026-12-01], billing_cycle: :monthly})

      now = ~U[2026-03-15 12:00:00Z]
      assert Renewals.roll_due(now) == 1

      rolled = Repo.reload!(past)
      assert rolled.next_renewal_on == ~D[2026-03-31]
      assert rolled.billing_anchor_on == ~D[2026-01-31]
      assert Repo.reload!(future).next_renewal_on == ~D[2026-12-01]

      assert Renewals.roll_due(now) == 0
    end

    test "ignores paused subscriptions" do
      scope = user_scope_fixture()

      paused =
        subscription_fixture(scope, %{
          next_renewal_on: ~D[2026-01-31],
          billing_cycle: :monthly,
          status: :paused
        })

      assert Renewals.roll_due(~U[2026-03-15 12:00:00Z]) == 0
      assert Repo.reload!(paused).next_renewal_on == ~D[2026-01-31]
    end
  end

  describe "anchor management" do
    test "editing the date resets the anchor, other edits keep it" do
      scope = user_scope_fixture()

      sub =
        subscription_fixture(scope, %{next_renewal_on: ~D[2026-01-31], billing_cycle: :monthly})

      # simulate a roll, which moves the date but never the anchor
      sub |> Ecto.Changeset.change(next_renewal_on: ~D[2026-02-28]) |> Repo.update!()

      {:ok, sub} = Subscriptions.update_subscription(scope, Repo.reload!(sub), %{notes: "x"})
      assert sub.billing_anchor_on == ~D[2026-01-31]

      {:ok, sub} = Subscriptions.update_subscription(scope, sub, %{next_renewal_on: "2026-03-15"})
      assert sub.billing_anchor_on == ~D[2026-03-15]
    end
  end
end
