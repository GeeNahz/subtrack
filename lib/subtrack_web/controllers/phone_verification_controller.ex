defmodule SubtrackWeb.PhoneVerificationController do
  use SubtrackWeb, :controller

  alias Subtrack.Accounts

  def new(conn, _params) do
    user = conn.assigns.current_scope.user

    cond do
      is_nil(user.phone_number) ->
        conn |> put_flash(:error, start_error(:no_phone)) |> redirect(to: ~p"/settings/contact")

      user.phone_confirmed_at ->
        redirect(conn, to: ~p"/settings/contact")

      true ->
        render(conn, :new)
    end
  end

  def send_code(conn, _params) do
    case Accounts.start_phone_verification(conn.assigns.current_scope) do
      {:ok, :sent} ->
        conn
        |> put_flash(:info, "We sent a 6-digit code to your phone.")
        |> redirect(to: ~p"/settings/phone/verify")

      {:error, reason} ->
        conn
        |> put_flash(:error, start_error(reason))
        |> redirect(to: ~p"/settings/phone/verify")
    end
  end

  def confirm(conn, %{"verification" => %{"code" => code}}) do
    case Accounts.confirm_phone(conn.assigns.current_scope, code) do
      {:ok, _user} ->
        conn
        |> put_flash(:info, "Phone number verified.")
        |> redirect(to: ~p"/settings/contact")

      {:error, reason} ->
        conn
        |> put_flash(:error, confirm_error(reason))
        |> redirect(to: ~p"/settings/phone/verify")
    end
  end

  defp start_error(:no_phone), do: "Add a mobile number first"
  defp start_error(:already_verified), do: "This number is already verified."
  defp start_error(:sms_failed), do: "We couldn't send the code. Please try again shortly."
  defp start_error({:cooldown, s}), do: "Please wait #{s} seconds before requesting another code."

  defp confirm_error(:invalid_code), do: "That code isn't right."
  defp confirm_error(:expired), do: "That code has expired. Request a new one."
  defp confirm_error(:too_many_attempts), do: "Too many attempts. Request a new one."
  defp confirm_error(:no_code), do: "Request a code first."
  defp confirm_error(%Ecto.Changeset{}), do: "We couldn't verify this number."
end
