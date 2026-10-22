defmodule Subtrack.Notifications.DispatcherTest do
  use ExUnit.Case, async: true

  alias Subtrack.Accounts.User
  alias Subtrack.Notifications.Dispatcher
  alias Subtrack.Subscriptions.{Reminder, Subscription}

  defp sms_args(user_attrs) do
    sub = %Subscription{
      name: "Netflix",
      amount: Decimal.new("15.00"),
      fee_amount: Decimal.new("0.99"),
      currency: "USD",
      next_renewal_on: ~D[2026-11-10]
    }

    {%Reminder{days_before: 5, note: nil}, sub, struct(User, user_attrs)}
  end

  test "client errors are permanent, except timeouts and rate limits" do
    assert {:permanent, _} = Dispatcher.classify_email_error({422, %{}})
    assert {:error, _} = Dispatcher.classify_email_error({429, %{}})
    assert {:error, _} = Dispatcher.classify_email_error({408, %{}})
  end

  test "server and transport errors are retryable" do
    assert {:error, _} = Dispatcher.classify_email_error({503, %{}})
    assert {:error, _} = Dispatcher.classify_email_error(:timeout)
  end

  test "sms is refused for missing or unverified numbers" do
    {r, s, u} = sms_args(phone_number: nil)
    assert {:permanent, :no_phone_number} = Dispatcher.deliver(:sms, r, s, u)

    {r, s, u} = sms_args(phone_number: "+2348012345678", phone_confirmed_at: nil)
    assert {:permanent, :phone_not_verified} = Dispatcher.deliver(:sms, r, s, u)
  end

  test "sms goes to a verified number" do
    {r, s, u} =
      sms_args(phone_number: "+2348012345678", phone_confirmed_at: ~U[2026-10-01 00:00:00Z])

    assert {:ok, _ref} = Dispatcher.deliver(:sms, r, s, u)
    assert_received {:sms, "+2348012345678", body}
    assert body =~ "Netflix renews in 5 days"
  end
end
