defmodule Subtrack.Subscriptions.Renewals do
  import Ecto.Query, warn: false

  alias Subtrack.Accounts.User
  alias Subtrack.Repo
  alias Subtrack.Subscriptions.{BillingCycles, Subscription}

  @batch_size 500

  # --- Pure decisions -------------

  @doc """
  Roll only when the local date is more than one day past the renewal date
  (a full day of margin after day-of reminders and their grace window)
  """
  def decide(%Subscription{} = sub, %Date{} = local_today) do
    if Date.compare(local_today, Date.add(sub.next_renewal_on, 1)) == :gt do
      {:roll,
       BillingCycles.next_on_or_after(sub.billing_anchor_on, sub.billing_cycle, local_today)}
    else
      :keep
    end
  end

  @doc """
  The user's calendar date right now. Falls back to UTC for a bad timezone.
  """
  def local_today(%DateTime{} = now, timezone) do
    case DateTime.shift_zone(now, timezone) do
      {:ok, local} -> DateTime.to_date(local)
      {:error, _reason} -> DateTime.to_date(now)
    end
  end

  # --- The batch job -------------

  @doc """
  Rolls every due subscription forward. Returns how many were changed.
  """
  def roll_due(now \\ DateTime.utc_now()) do
    roll_batches(DateTime.to_date(now), now, nil, 0)
  end

  defp roll_batches(utc_today, now, after_id, total) do
    case fetch_batch(utc_today, after_id) do
      [] ->
        total

      rows ->
        rolled = rows |> Enum.map(&roll_one(&1, now)) |> Enum.sum()
        {last, _timezone} = List.last(rows)
        roll_batches(utc_today, now, last.id, total + rolled)
    end
  end

  # Coarse SQL filter. local_today can be at most one day ahead of UTC today, so
  # "renewal <= utc_today" is a safe superset of "renewal < local_today - 1"
  defp fetch_batch(utc_today, after_id) do
    batch_size = @batch_size

    query =
      from(s in Subscription,
        join: u in User,
        on: u.id == s.user_id,
        where: s.status == :active and s.next_renewal_on <= ^utc_today,
        order_by: s.id,
        limit: ^batch_size,
        select: {s, u.timezone}
      )

    query = if after_id, do: where(query, [s], s.id > ^after_id), else: query
    Repo.all(query)
  end

  defp roll_one({sub, timezone}, now) do
    case decide(sub, local_today(now, timezone)) do
      :keep ->
        0

      {:roll, new_date} ->
        # Guard on the old date: if the user edited it meanwhile, we change nothing.
        {count, _} =
          Repo.update_all(
            from(s in Subscription,
              where: s.id == ^sub.id and s.next_renewal_on == ^sub.next_renewal_on
            ),
            set: [next_renewal_on: new_date, updated_at: DateTime.utc_now(:second)]
          )

        count
    end
  end
end
