defmodule SubtrackWeb.ContactSettingsControllerTest do
  use SubtrackWeb.ConnCase

  alias Subtrack.Accounts

  setup :register_and_log_in_user

  test "renders the form", %{conn: conn} do
    assert html_response(get(conn, ~p"/settings/contact"), 200) =~ "Timezone"
  end

  test "saves timezone and phone", %{conn: conn, user: user} do
    conn =
      put(conn, ~p"/settings/contact",
        user: %{timezone: "Africa/Lagos", phone_number: "+2348012345678"}
      )

    assert redirected_to(conn) == ~p"/settings/contact"

    user = Accounts.get_user!(user.id)
    assert user.timezone == "Africa/Lagos"
    assert user.phone_number == "+2348012345678"
  end

  test "re-renders with errors", %{conn: conn} do
    conn = put(conn, ~p"/settings/contact", user: %{timezone: "Mars/Olympus"})
    assert html_response(conn, 200) =~ "is not a valid timezone"
  end

  test "requires login" do
    conn = get(build_conn(), ~p"/settings/contact")
    assert redirected_to(conn) == ~p"/users/log-in"
  end
end
