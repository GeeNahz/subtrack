defmodule Subtrack.Notifications.Schedule do
  @moduledoc """
  Decides *when* a reminder is due. No database access.
  """
  @grace_seconds 6 * 60 * 60

  @doc """
  The UTC moment a reminder should fire for a given renewal date.
  """
  def due_at(%Date{} = renewal_on, days_before, %Time{} = send_at, timezone) do
    renewal_on
    |> Date.add(-days_before)
    |> DateTime.new(send_at, timezone)
    |> case do
      {:ok, local} -> {:ok, to_utc(local)}
      {:ambiguous, first, _second} -> {:ok, to_utc(first)}
      {:gap, _just_before, just_after} -> {:ok, to_utc(just_after)}
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  :upcoming (not yet), :due (send it), or :expired (too late, skip it).
  """
  def state(%DateTime{} = due_at, %DateTime{} = now) do
    seconds_late = DateTime.diff(now, due_at)

    cond do
      seconds_late < 0 -> :upcoming
      seconds_late <= @grace_seconds -> :due
      true -> :expired
    end
  end

  defp to_utc(datetime), do: DateTime.shift_zone!(datetime, "Etc/UTC")
end
