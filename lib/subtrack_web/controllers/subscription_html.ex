defmodule SubtrackWeb.SubscriptionHTML do
  use SubtrackWeb, :html

  embed_templates "subscription_html/*"

  @doc """
  Renders a subscription form.

  The form is defined in the template at
  subscription_html/subscription_form.html.heex
  """
  attr :changeset, Ecto.Changeset, required: true
  attr :action, :string, required: true
  attr :return_to, :string, default: nil
  attr :payment_method_options, :list, required: true

  def subscription_form(assigns)

  def money(nil, _currency), do: "-"

  def money(%Decimal{} = amount, currency) do
    "#{currency} #{amount |> Decimal.round(2) |> Decimal.to_string(:normal)}"
  end

  def reminder_summary(%{days_before: 0, send_at: t}), do: "On the day, at #{time(t)}"

  def reminder_summary(%{days_before: d, send_at: t}),
    do: "#{d} #{if d == 1, do: "day", else: "days"} before, at #{time(t)}"

  defp time(t), do: Calendar.strftime(t, "%H:%M")
end
