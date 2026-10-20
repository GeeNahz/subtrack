defmodule Subtrack.Workers.RollRenewals do
  use Oban.Worker, queue: :default, max_attempts: 1

  require Logger

  @impl Oban.Worker
  def perform(_job) do
    count = Subtrack.Subscriptions.Renewals.roll_due()
    if count > 0, do: Logger.info("Rolled #{count} renewal dates forward")
    :ok
  end
end
