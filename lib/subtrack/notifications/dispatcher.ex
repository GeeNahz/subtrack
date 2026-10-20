defmodule Subtrack.Notifications.Dispatcher do
  @moduledoc """
  Sends one reminder over one channel. Returns:

  * `{:ok, provider_ref}`   sent
  * `{:error, reason}`      transient, worth retrying
  * `{:permanent, reason}`  can never succeed, don't retry
  """
  require Logger

  alias Subtrack.Mailer
  alias Subtrack.Notifications.ReminderEmail

  def deliver(:email, reminder, subscription, user) do
    reminder
    |> ReminderEmail.build(subscription, user)
    |> Mailer.deliver()
    |> case do
      {:ok, meta} -> {:ok, provider_ref(meta)}
      {:error, reason} -> classify_email_error(reason)
    end
  end

  # Stage 10 replaces this with real SMS sender.
  def deliver(:sms, _reminder, subscription, user) do
    Logger.info("[sub] sms reminder: #{subscription.name} -> user #{user.id}")
    {:ok, "stub-sms-#{Ecto.UUID.generate()}"}
  end

  @doc false
  def classify_email_error({status, _body} = reason)
      when status in 400..499 and status not in [408, 429],
      do: {:permanent, reason}

  def classify_email_error(reason), do: {:error, reason}

  defp provider_ref(%{id: id}) when is_binary(id), do: id
  defp provider_ref(_), do: nil
end
