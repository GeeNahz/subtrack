defmodule Subtrack.SMS.Log do
  @behaviour Subtrack.SMS
  require Logger

  @impl true
  def deliver(to, body) do
    Logger.info("[sms:dev] to #{to}: #{body}")
    {:ok, "dev-" <> Ecto.UUID.generate()}
  end
end
