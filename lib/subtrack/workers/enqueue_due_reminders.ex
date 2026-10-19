defmodule Subtrack.Workers.EnqueueDueReminders do
  use Oban.Worker, queue: :default, max_attempts: 1

  require Logger

  @impl Oban.Worker
  def perform(_job) do
    count = Subtrack.Notifications.enqueue_due()
    if count > 0, do: Logger.info("Enqueue #{count} reminder deliveries")
    :ok
  end
end
