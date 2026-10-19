defmodule Subtrack.Notifications.Dispatcher do
  require Logger

  def deliver(channel, _reminder, subscription, user) do
    if System.get_env("STUB_FAIL") == "1" do
      # Logger.info()
      {:error, :stub_failure}
    else
      Logger.info("[sub] #{channel} reminder: #{subscription.name} -> #{user.email}")
      {:ok, "stub-#{Ecto.UUID.generate()}"}
    end
  end
end
