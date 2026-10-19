defmodule Subtrack.Notifications.Dispatcher do
  require Logger

  def deliver(channel, _reminder, subscription, user) do
    Logger.info("[sub] #{channel} reminder: #{subscription.name} -> #{user.email}")
    {:ok, "stub-#{Ecto.UUID.generate()}"}
  end
end
