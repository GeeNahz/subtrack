defmodule Subtrack.Notifications.DispatcherTest do
  use ExUnit.Case, async: true
  alias Subtrack.Notifications.Dispatcher

  test "client errors are permanent, except timeouts and rate limits" do
    assert {:permanent, _} = Dispatcher.classify_email_error({422, %{}})
    assert {:error, _} = Dispatcher.classify_email_error({429, %{}})
    assert {:error, _} = Dispatcher.classify_email_error({408, %{}})
  end

  test "server and transport errors are retryable" do
    assert {:error, _} = Dispatcher.classify_email_error({503, %{}})
    assert {:error, _} = Dispatcher.classify_email_error(:timeout)
  end
end
