defmodule SubtrackWeb.ProfileSettingsController do
  use SubtrackWeb, :controller

  # import Phoenix.Component, only: [to_form: 1, to_form: 2]

  alias Subtrack.Accounts

  def edit(conn, _params) do
    profile = Accounts.get_profile!(conn.assigns.current_scope)
    render(conn, :edit, form: Accounts.change_profile(profile))
  end

  def update(conn, %{"profile" => params}) do
    case Accounts.update_profile(conn.assigns.current_scope, params) do
      {:ok, _profile} ->
        conn
        |> put_flash(:info, "Profile updated.")
        |> redirect(to: ~p"/settings/profile")

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :edit, form: changeset)
    end
  end
end
