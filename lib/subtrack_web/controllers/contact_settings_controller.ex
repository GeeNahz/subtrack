defmodule SubtrackWeb.ContactSettingsController do
  use SubtrackWeb, :controller

  alias Subtrack.Accounts

  def edit(conn, _params) do
    user = conn.assigns.current_scope.user
    render(conn, :edit, form: Accounts.change_user_contact(user, %{}))
  end

  def update(conn, %{"user" => params}) do
    case Accounts.update_user_contact(conn.assigns.current_scope, params) do
      {:ok, _user} ->
        conn
        |> put_flash(:info, "Contact settings updated.")
        |> redirect(to: ~p"/settings/contact")

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :edit, form: changeset)
    end
  end
end
