defmodule Subtrack.Notifications.ReminderEmailTest do
  use ExUnit.Case, async: true

  alias Subtrack.Accounts.{Profile, User}
  alias Subtrack.Notifications.ReminderEmail
  alias Subtrack.Subscriptions.{PaymentMethod, Reminder, Subscription}

  defp build(reminder_attrs \\ []) do
    user = %User{email: "ada@example.com", profile: %Profile{first_name: "Ada"}}
    card = %PaymentMethod{nickname: "GTB Dollar", brand: :visa, last4: "1234", currency: "NGN"}

    sub = %Subscription{
      id: Ecto.UUID.generate(),
      name: "Netflix",
      plan_name: "Premium",
      amount: Decimal.new("15.00"),
      fee_amount: Decimal.new("0.99"),
      currency: "USD",
      fx_rate: Decimal.new("1600"),
      next_renewal_on: ~D[2026-11-10],
      payment_method: card
    }

    reminder = struct(%Reminder{days_before: 5, note: nil}, reminder_attrs)
    ReminderEmail.build(reminder, sub, user)
  end

  test "subject and greeting reflect the rule and the user" do
    email = build()
    assert email.subject == "Netflix renews in 5 days"
    assert email.text_body =~ "Hi Ada,"
    assert email.to == [{"Ada", "ada@example.com"}]
  end

  test "shows the amount, the card estimate, and the card" do
    body = build().text_body

    assert body =~ "Amount: USD 15.99"
    assert body =~ "NGN 25584.00"
    assert body =~ "**1234"
  end

  test "wording for 0 and 1 days" do
    assert build(days_before: 0).subject == "Netflix renews today"
    assert build(days_before: 1).subject == "Netflix renews tomorrow"
  end

  test "includes the note only when present" do
    assert build(note: "Cancel before the trial ends").text_body =~
             "Your note: Cancel before the trial ends"

    refute build(note: "   ").text_body =~ "Your note"
    refute build().text_body =~ "Your note"
  end
end
