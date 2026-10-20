defmodule Subtrack.Subscriptions.BillingCycles do
  @moduledoc """
  The billing cycle list, and all date arithmetic for cycles. Pure.
  """

  @order [:weekly, :monthly, :quarterly, :yearly]

  @steps %{
    weekly: {:days, 7},
    monthly: {:months, 1},
    quarterly: {:months, 3},
    yearly: {:months, 12}
  }

  @labels %{weekly: "Weekly", monthly: "Monthly", quarterly: "Quarterly", yearly: "Yearly"}

  def all, do: @order
  def label(cycle), do: Map.fetch!(@labels, cycle)

  @doc """
  The nth occurrence of a cycle, always computed from the anchor.
  Never chain from a previous result, or month-end clamping diffs.
  """
  def occurrence(%Date{} = anchor, cycle, n) when n >= 0 do
    case Map.fetch!(@steps, cycle) do
      {:days, days} -> Date.shift(anchor, day: days * n)
      {:months, months} -> Date.shift(anchor, month: months * n)
    end
  end

  @doc """
  The first occurrence on or after `date`.
  """
  def next_on_or_after(%Date{} = anchor, cycle, %Date{} = date) do
    find(anchor, cycle, date, start_index(anchor, cycle, date))
  end

  defp find(anchor, cycle, date, n) do
    candidate = occurrence(anchor, cycle, n)

    if Date.compare(candidate, date) == :lt, do: find(anchor, cycle, date, n + 1), else: candidate
  end

  # A safe lower bound for the answer, so we never overshoot.
  defp start_index(anchor, cycle, date) do
    n =
      case Map.fetch!(@steps, cycle) do
        {:days, days} -> div(Date.diff(date, anchor), days)
        {:months, months} -> div(months_between(anchor, date), months)
      end

    max(n, 0)
  end

  defp months_between(a, b), do: (b.year - a.year) * 12 + (b.month - a.month)
end
