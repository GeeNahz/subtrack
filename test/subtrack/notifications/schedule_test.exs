defmodule Subtrack.Notifications.ScheduleTest do
  use ExUnit.Case, async: true
  alias Subtrack.Notifications.Schedule

  test "Lagos is UTC+1, so 09:00 local is 08:00Z" do
    assert {:ok, due} = Schedule.due_at(~D[2026-11-10], 5, ~T[09:00:00], "Africa/Lagos")
    assert due == ~U[2026-11-05 08:00:00Z]
  end

  test "daylight saving: New York is UTC-5 in November" do
    assert {:ok, due} = Schedule.due_at(~D[2026-11-10], 5, ~T[09:00:00], "America/New_York")
    assert due == ~U[2026-11-05 14:00:00Z]
  end

  test "a time inside a spring-forward gap moves to the first valid moment" do
    assert {:ok, due} = Schedule.due_at(~D[2026-03-10], 2, ~T[02:30:00], "America/New_York")
    assert due == ~U[2026-03-08 07:00:00Z]
  end

  test "an ambiguous fall-back time picks the first occurence" do
    assert {:ok, due} = Schedule.due_at(~D[2026-11-03], 2, ~T[01:30:00], "America/New_York")
    assert due == ~U[2026-11-01 05:30:00Z]
  end

  test "state/2 covers upcoming, due, and expired" do
    due = ~U[2026-11-05 09:00:00Z]
    assert Schedule.state(due, ~U[2026-11-05 08:59:00Z]) == :upcoming
    assert Schedule.state(due, ~U[2026-11-05 09:10:00Z]) == :due
    assert Schedule.state(due, ~U[2026-11-05 15:00:01Z]) == :expired
  end
end
