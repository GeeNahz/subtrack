defmodule SubtrackWeb.PaymentMethodControllerTest do
  use SubtrackWeb.ConnCase

  import Subtrack.SubscriptionsFixtures

  @create_attrs %{
    currency: "usd",
    nickname: "some nickname",
    brand: :visa,
    card_mode: :physical,
    last4: "1234",
    bank_name: "some bank_name",
    expiry_month: 12,
    expiry_year: 2028
  }
  @update_attrs %{
    currency: "gbp",
    nickname: "some updated nickname",
    brand: :mastercard,
    card_mode: :virtual,
    last4: "3456",
    bank_name: "some updated bank_name",
    expiry_month: 5,
    expiry_year: 2030
  }
  @invalid_attrs %{
    currency: nil,
    nickname: nil,
    brand: nil,
    card_mode: nil,
    last4: nil,
    bank_name: nil,
    expiry_month: nil,
    expiry_year: nil
  }

  setup :register_and_log_in_user

  describe "index" do
    test "lists all payment_methods", %{conn: conn} do
      conn = get(conn, ~p"/payment_methods")
      assert html_response(conn, 200) =~ "Listing Payment methods"
    end
  end

  describe "new payment_method" do
    test "renders form", %{conn: conn} do
      conn = get(conn, ~p"/payment_methods/new")
      assert html_response(conn, 200) =~ "New Payment method"
    end
  end

  describe "create payment_method" do
    test "redirects to show when data is valid", %{conn: conn} do
      conn = post(conn, ~p"/payment_methods", payment_method: @create_attrs)

      assert %{id: id} = redirected_params(conn)
      assert redirected_to(conn) == ~p"/payment_methods/#{id}"

      conn = get(conn, ~p"/payment_methods/#{id}")
      assert html_response(conn, 200) =~ "Payment method #{id}"
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, ~p"/payment_methods", payment_method: @invalid_attrs)
      assert html_response(conn, 200) =~ "New Payment method"
    end
  end

  describe "edit payment_method" do
    setup [:create_payment_method]

    test "renders form for editing chosen payment_method", %{
      conn: conn,
      payment_method: payment_method
    } do
      conn = get(conn, ~p"/payment_methods/#{payment_method}/edit")
      assert html_response(conn, 200) =~ "Edit Payment method"
    end
  end

  describe "update payment_method" do
    setup [:create_payment_method]

    test "redirects when data is valid", %{conn: conn, payment_method: payment_method} do
      conn = put(conn, ~p"/payment_methods/#{payment_method}", payment_method: @update_attrs)
      assert redirected_to(conn) == ~p"/payment_methods/#{payment_method}"

      conn = get(conn, ~p"/payment_methods/#{payment_method}")
      assert html_response(conn, 200) =~ "some updated nickname"
    end

    test "renders errors when data is invalid", %{conn: conn, payment_method: payment_method} do
      conn = put(conn, ~p"/payment_methods/#{payment_method}", payment_method: @invalid_attrs)
      assert html_response(conn, 200) =~ "Edit Payment method"
    end
  end

  describe "delete payment_method" do
    setup [:create_payment_method]

    test "deletes chosen payment_method", %{conn: conn, payment_method: payment_method} do
      conn = delete(conn, ~p"/payment_methods/#{payment_method}")
      assert redirected_to(conn) == ~p"/payment_methods"

      assert_error_sent 404, fn ->
        get(conn, ~p"/payment_methods/#{payment_method}")
      end
    end
  end

  defp create_payment_method(%{scope: scope}) do
    payment_method = payment_method_fixture(scope)

    %{payment_method: payment_method}
  end
end
