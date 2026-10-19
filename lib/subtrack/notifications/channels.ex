defmodule Subtrack.Notifications.Channels do
  @channels [:email, :sms]

  def all, do: @channels
end
