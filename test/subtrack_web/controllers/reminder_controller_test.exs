defmodule SubtrackWeb.ReminderControllerTest do
  use SubtrackWeb.ConnCase

  import Subtrack.AccountsFixtures
  import Subtrack.SubscriptionsFixtures

  setup :register_and_log_in_user

  setup %{scope: scope} do
    %{subscription: subscription_fixture(scope)}
  end

  test "creates a reminder and redirects to the subscription", %{conn: conn, subscription: sub} do
    params = %{days_before: 5, send_at: "09:00", enabled: true, channels: [:email]}
    conn = post(conn, ~p"/subscriptions/#{sub}/reminders", reminder: params)
    assert redirected_to(conn) == ~p"/subscriptions/#{sub}"
  end

  test "404s for another user's subscription", %{conn: conn} do
    other = subscription_fixture(user_scope_fixture())
    assert_error_sent(404, fn -> get(conn, ~p"/subscriptions/#{other}/reminders/new") end)
  end
end
