defmodule Subtrack.Notifications.ReminderEmail do
  import Swoosh.Email
  use Phoenix.VerifiedRoutes, endpoint: SubtrackWeb.Endpoint, router: SubtrackWeb.Router

  alias Subtrack.Money
  alias Subtrack.Subscriptions.{PaymentMethod, Subscription}

  def build(reminder, subscription, user) do
    new()
    |> to(recipient(user))
    |> from(Application.fetch_env!(:subtrack, :mail_from))
    |> subject("#{subscription.name} #{when_text(reminder.days_before)}")
    |> text_body(body(reminder, subscription, user))
  end

  defp body(reminder, subscription, user) do
    link = url(~p"/subscriptions/#{subscription.id}")

    ([greeting(user), "", headline(subscription, reminder), ""] ++
       charge_lines(subscription) ++
       note_lines(reminder) ++ ["", "Manage this subscription: #{link}", "", "- Subtrack"])
    |> Enum.join("\n")
  end

  defp headline(sub, reminder) do
    name = if sub.plan_name in [nil, ""], do: sub.name, else: "#{sub.name} (#{sub.plan_name})"
    date = Calendar.strftime(sub.next_renewal_on, "%A, %d %B %Y")
    "Your #{name} subscription #{when_text(reminder.days_before)}, on #{date}."
  end

  defp when_text(0), do: "renews today"
  defp when_text(1), do: "renews tomorrow"
  defp when_text(n), do: "renews in #{n} days"

  defp charge_lines(sub) do
    [
      "Amount: #{Money.format(Subscription.total_amount(sub), sub.currency)}",
      fee_line(sub),
      estimate_line(sub),
      card_line(sub)
    ]
    |> Enum.reject(&is_nil/1)
  end

  defp fee_line(sub) do
    if Decimal.gt?(sub.fee_amount, 0) do
      " (plan #{Money.format(sub.amount, sub.currency)} + fees #{Money.format(sub.fee_amount, sub.currency)})"
    end
  end

  defp estimate_line(sub) do
    case Subscription.estimated_card_charge(sub) do
      nil ->
        nil

      estimate ->
        rate = sub.fx_rate |> Decimal.normalize() |> Decimal.to_string(:normal)

        "Estimated card debit: ~ #{Money.format(estimate, sub.payment_method.currency)} (at #{rate})"
    end
  end

  defp card_line(%{payment_method: %PaymentMethod{} = pm}), do: "Card #{PaymentMethod.label(pm)}"
  defp card_line(_), do: nil

  defp note_lines(%{note: note}) when is_binary(note) do
    case String.trim(note) do
      "" -> []
      text -> ["", "Your note: #{text}"]
    end
  end

  defp note_lines(_), do: []

  defp greeting(user), do: if(name = first_name(user), do: "Hi #{name},", else: "Hi, ")

  defp recipient(user) do
    case first_name(user) do
      nil -> user.email
      name -> {name, user.email}
    end
  end

  defp first_name(%{profile: %{first_name: name}}) when is_binary(name), do: name
  defp first_name(_), do: nil
end
