defmodule Subtrack.Subscriptions.BillingCyclesTest do
  use ExUnit.Case, async: false

  alias Subtrack.Subscriptions.BillingCycles, as: BC

  test "month-end anchors clamp but do not drift" do
    anchor = ~D[2026-01-31]
    assert BC.occurrence(anchor, :monthly, 0) == ~D[2026-01-31]
    assert BC.occurrence(anchor, :monthly, 1) == ~D[2026-02-28]
    assert BC.occurrence(anchor, :monthly, 2) == ~D[2026-03-31]
    assert BC.occurrence(anchor, :monthly, 3) == ~D[2026-04-30]
  end

  test "leap years" do
    assert BC.occurrence(~D[2028-01-31], :monthly, 1) == ~D[2028-02-29]
    assert BC.occurrence(~D[2024-02-29], :yearly, 1) == ~D[2025-02-28]
    assert BC.occurrence(~D[2024-02-29], :yearly, 4) == ~D[2028-02-29]
  end

  test "next_on_or_after is inclusive" do
    anchor = ~D[2026-01-31]

    assert BC.next_on_or_after(anchor, :monthly, ~D[2026-02-15]) == ~D[2026-02-28]
    assert BC.next_on_or_after(anchor, :monthly, ~D[2026-02-28]) == ~D[2026-02-28]
    assert BC.next_on_or_after(anchor, :monthly, ~D[2026-03-01]) == ~D[2026-03-31]
  end

  test "catches up across many missed cycles" do
    assert BC.next_on_or_after(~D[2025-01-31], :monthly, ~D[2026-10-22]) == ~D[2026-10-31]
  end

  test "weekly and quarterly" do
    assert BC.next_on_or_after(~D[2026-10-20], :weekly, ~D[2026-10-22]) == ~D[2026-10-27]
    assert BC.next_on_or_after(~D[2026-10-20], :weekly, ~D[2026-10-27]) == ~D[2026-10-27]
    assert BC.next_on_or_after(~D[2026-01-31], :quarterly, ~D[2026-05-01]) == ~D[2026-07-31]
  end

  test "an anchor in the future is its own first occurrence" do
    assert BC.next_on_or_after(~D[2027-01-01], :monthly, ~D[2026-10-20]) == ~D[2027-01-01]
  end
end
