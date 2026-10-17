defmodule SubtrackWeb.SubscriptionController do
  use SubtrackWeb, :controller

  alias Subtrack.Subscriptions
  alias Subtrack.Subscriptions.Subscription

  def index(conn, _params) do
    subscriptions = Subscriptions.list_subscriptions(conn.assigns.current_scope)
    render(conn, :index, subscriptions: subscriptions)
  end

  def new(conn, _params) do
    changeset =
      Subscriptions.change_subscription(conn.assigns.current_scope, %Subscription{
        user_id: conn.assigns.current_scope.user.id
      })

    render(conn, :new, changeset: changeset, payment_method_options: payment_method_options(conn))
  end

  def create(conn, %{"subscription" => subscription_params}) do
    case Subscriptions.create_subscription(conn.assigns.current_scope, subscription_params) do
      {:ok, subscription} ->
        conn
        |> put_flash(:info, "Subscription created successfully.")
        |> redirect(to: ~p"/subscriptions/#{subscription}")

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :new,
          changeset: changeset,
          payment_method_options: payment_method_options(conn)
        )
    end
  end

  def show(conn, %{"id" => id}) do
    scope = conn.assigns.current_scope
    subscription = Subscriptions.get_subscription!(scope, id)
    reminders = Subscriptions.list_reminders(scope, subscription)
    render(conn, :show, subscription: subscription, reminders: reminders)
  end

  def edit(conn, %{"id" => id}) do
    subscription = Subscriptions.get_subscription!(conn.assigns.current_scope, id)
    changeset = Subscriptions.change_subscription(conn.assigns.current_scope, subscription)

    render(conn, :edit,
      subscription: subscription,
      changeset: changeset,
      payment_method_options: payment_method_options(conn)
    )
  end

  def update(conn, %{"id" => id, "subscription" => subscription_params}) do
    subscription = Subscriptions.get_subscription!(conn.assigns.current_scope, id)

    case Subscriptions.update_subscription(
           conn.assigns.current_scope,
           subscription,
           subscription_params
         ) do
      {:ok, subscription} ->
        conn
        |> put_flash(:info, "Subscription updated successfully.")
        |> redirect(to: ~p"/subscriptions/#{subscription}")

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :edit,
          subscription: subscription,
          changeset: changeset,
          payment_method_options: payment_method_options(conn)
        )
    end
  end

  def delete(conn, %{"id" => id}) do
    subscription = Subscriptions.get_subscription!(conn.assigns.current_scope, id)

    {:ok, _subscription} =
      Subscriptions.delete_subscription(conn.assigns.current_scope, subscription)

    conn
    |> put_flash(:info, "Subscription deleted successfully.")
    |> redirect(to: ~p"/subscriptions")
  end

  defp payment_method_options(conn) do
    conn.assigns.current_scope
    |> Subscriptions.list_payment_methods()
    |> Enum.map(&{Subtrack.Subscriptions.PaymentMethod.label(&1), &1.id})
  end
end
