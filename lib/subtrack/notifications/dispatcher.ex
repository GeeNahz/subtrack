defmodule Subtrack.Notifications.Dispatcher do
  @moduledoc """
  Sends one reminder over one channel. Returns:

  * `{:ok, provider_ref}`   sent
  * `{:error, reason}`      transient, worth retrying
  * `{:permanent, reason}`  can never succeed, don't retry
  """
  require Logger

  alias Subtrack.Mailer
  alias Subtrack.SMS
  alias Subtrack.Notifications.{ReminderEmail, ReminderSms}

  def deliver(:email, reminder, subscription, user) do
    reminder
    |> ReminderEmail.build(subscription, user)
    |> Mailer.deliver()
    |> case do
      {:ok, meta} -> {:ok, provider_ref(meta)}
      {:error, reason} -> classify_email_error(reason)
    end
  end

  def deliver(:sms, reminder, subscription, user) do
    cond do
      is_nil(user.phone_number) ->
        {:permanent, :no_phone_number}

      is_nil(user.phone_confirmed_at) ->
        {:permanent, :phone_not_verified}

      true ->
        SMS.deliver(user.phone_number, ReminderSms.build(reminder, subscription))
    end
  end

  @doc false
  def classify_email_error({status, _body} = reason)
      when status in 400..499 and status not in [408, 429],
      do: {:permanent, reason}

  def classify_email_error(reason), do: {:error, reason}

  defp provider_ref(%{id: id}) when is_binary(id), do: id
  defp provider_ref(_), do: nil
end
