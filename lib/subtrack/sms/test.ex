defmodule Subtrack.SMS.Test do
  @behaviour Subtrack.SMS

  @impl true
  def deliver(to, body) do
    send(self(), {:sms, to, body})
    # Tests can force a failure with Process.put(:sms_result, {:error, :boom})
    Process.get(:sms_result, {:ok, "test-sms"})
  end
end
