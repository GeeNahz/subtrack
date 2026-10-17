defmodule SubtrackWeb.ReminderController do
  use SubtrackWeb, :controller

  alias Subtrack.Subscriptions
  alias Subtrack.Subscriptions.Reminder

  plug :load_subscription

  def new(conn, _params) do
    %{current_scope: scope, subscription: subscription} = conn.assigns

    changeset =
      Subscriptions.change_reminder(scope, %Reminder{
        user_id: scope.user.id,
        subscription_id: subscription.id
      })

    render(conn, :new, changeset: changeset)
  end

  def create(conn, %{"reminder" => params}) do
    %{current_scope: scope, subscription: subscription} = conn.assigns

    case Subscriptions.create_reminder(scope, subscription, params) do
      {:ok, _reminder} ->
        conn
        |> put_flash(:info, "Reminder added.")
        |> redirect_to_subscriptions(subscription)

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :new, changeset: changeset)
    end
  end

  def edit(conn, %{"id" => id}) do
    %{current_scope: scope, subscription: subscription} = conn.assigns

    reminder = Subscriptions.get_reminder!(scope, subscription, id)

    render(conn, :edit,
      reminder: reminder,
      changeset: Subscriptions.change_reminder(scope, reminder)
    )
  end

  def update(conn, %{"id" => id, "reminder" => params}) do
    %{current_scope: scope, subscription: subscription} = conn.assigns

    reminder = Subscriptions.get_reminder!(scope, subscription, id)

    case Subscriptions.update_reminder(scope, reminder, params) do
      {:ok, _reminder} ->
        conn
        |> put_flash(:info, "Reminder updated.")
        |> redirect_to_subscriptions(subscription)

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :edit, reminder: reminder, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    %{current_scope: scope, subscription: subscription} = conn.assigns
    reminder = Subscriptions.get_reminder!(scope, subscription, id)
    {:ok, _reminder} = Subscriptions.delete_reminder(scope, reminder)

    conn
    |> put_flash(:info, "Reminder deleted.")
    |> redirect_to_subscriptions(subscription)
  end

  defp redirect_to_subscriptions(%Plug.Conn{} = conn, subscription) do
    conn
    |> redirect(to: ~p"/subscriptions/#{subscription}")
  end

  defp load_subscription(conn, _opts) do
    subscription =
      Subscriptions.get_subscription!(conn.assigns.current_scope, conn.params["subscription_id"])

    assign(conn, :subscription, subscription)
  end

  # unused
  # def index(conn, _params) do
  #   reminders = Subscriptions.list_reminders(conn.assigns.current_scope)
  #   render(conn, :index, reminders: reminders)
  # end
  #
  # def show(conn, %{"id" => id}) do
  #   %{current_scope: scope, subscription: subscription} = conn.assigns
  #   reminder = Subscriptions.get_reminder!(scope, subscription, id)
  #   render(conn, :show, reminder: reminder)
  # end
end
