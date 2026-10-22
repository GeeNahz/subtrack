defmodule Subtrack.SMS do
  @moduledoc """
  Sends a text message through the configured adapter.
  """
  @callback deliver(to :: String.t(), body :: String.t()) ::
              {:ok, String.t() | nil} | {:error, term()} | {:permanent, term()}

  def deliver(to, body), do: adapter().deliver(to, body)

  # Read at runtime, never in a module attribute (same release gotcha as :mail_from).
  defp adapter, do: Application.fetch_env!(:subtrack, :sms_adapter)
end
