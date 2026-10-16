defmodule SubtrackWeb.SubscriptionControllerTest do
  use SubtrackWeb.ConnCase

  import Subtrack.SubscriptionsFixtures

  @create_attrs %{
    name: "some name",
    status: :active,
    currency: "GBP",
    amount: "120.5",
    plan_name: "some plan_name",
    fee_amount: "120.5",
    fx_rate: "120.5",
    billing_cycle: :weekly,
    next_renewal_on: ~D[2026-10-12],
    manage_url: "some manage_url",
    notes: "some notes"
  }
  @update_attrs %{
    name: "some updated name",
    status: :paused,
    currency: "GBP",
    amount: "456.7",
    plan_name: "some updated plan_name",
    fee_amount: "456.7",
    fx_rate: "456.7",
    billing_cycle: :monthly,
    next_renewal_on: ~D[2026-10-13],
    manage_url: "some updated manage_url",
    notes: "some updated notes"
  }
  @invalid_attrs %{
    name: nil,
    status: nil,
    currency: nil,
    amount: nil,
    plan_name: nil,
    fee_amount: nil,
    fx_rate: nil,
    billing_cycle: nil,
    next_renewal_on: nil,
    manage_url: nil,
    notes: nil
  }

  setup :register_and_log_in_user

  describe "index" do
    test "lists all subscriptions", %{conn: conn} do
      conn = get(conn, ~p"/subscriptions")
      assert html_response(conn, 200) =~ "Listing Subscriptions"
    end
  end

  describe "new subscription" do
    test "renders form", %{conn: conn} do
      conn = get(conn, ~p"/subscriptions/new")
      assert html_response(conn, 200) =~ "New Subscription"
    end
  end

  describe "create subscription" do
    test "redirects to show when data is valid", %{conn: conn} do
      conn = post(conn, ~p"/subscriptions", subscription: @create_attrs)

      assert %{id: id} = redirected_params(conn)
      assert redirected_to(conn) == ~p"/subscriptions/#{id}"

      conn = get(conn, ~p"/subscriptions/#{id}")
      assert html_response(conn, 200) =~ "Subscription #{id}"
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, ~p"/subscriptions", subscription: @invalid_attrs)
      assert html_response(conn, 200) =~ "New Subscription"
    end
  end

  describe "edit subscription" do
    setup [:create_subscription]

    test "renders form for editing chosen subscription", %{conn: conn, subscription: subscription} do
      conn = get(conn, ~p"/subscriptions/#{subscription}/edit")
      assert html_response(conn, 200) =~ "Edit Subscription"
    end
  end

  describe "update subscription" do
    setup [:create_subscription]

    test "redirects when data is valid", %{conn: conn, subscription: subscription} do
      conn = put(conn, ~p"/subscriptions/#{subscription}", subscription: @update_attrs)
      assert redirected_to(conn) == ~p"/subscriptions/#{subscription}"

      conn = get(conn, ~p"/subscriptions/#{subscription}")
      assert html_response(conn, 200) =~ "some updated name"
    end

    test "renders errors when data is invalid", %{conn: conn, subscription: subscription} do
      conn = put(conn, ~p"/subscriptions/#{subscription}", subscription: @invalid_attrs)
      assert html_response(conn, 200) =~ "Edit Subscription"
    end
  end

  describe "delete subscription" do
    setup [:create_subscription]

    test "deletes chosen subscription", %{conn: conn, subscription: subscription} do
      conn = delete(conn, ~p"/subscriptions/#{subscription}")
      assert redirected_to(conn) == ~p"/subscriptions"

      assert_error_sent 404, fn ->
        get(conn, ~p"/subscriptions/#{subscription}")
      end
    end
  end

  defp create_subscription(%{scope: scope}) do
    subscription = subscription_fixture(scope)

    %{subscription: subscription}
  end
end
