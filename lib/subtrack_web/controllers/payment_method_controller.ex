defmodule SubtrackWeb.PaymentMethodController do
  use SubtrackWeb, :controller

  alias Subtrack.Subscriptions
  alias Subtrack.Subscriptions.PaymentMethod

  def index(conn, _params) do
    payment_methods = Subscriptions.list_payment_methods(conn.assigns.current_scope)
    render(conn, :index, payment_methods: payment_methods)
  end

  def new(conn, _params) do
    changeset =
      Subscriptions.change_payment_method(conn.assigns.current_scope, %PaymentMethod{
        user_id: conn.assigns.current_scope.user.id
      })

    render(conn, :new, changeset: changeset)
  end

  def create(conn, %{"payment_method" => payment_method_params}) do
    case Subscriptions.create_payment_method(conn.assigns.current_scope, payment_method_params) do
      {:ok, payment_method} ->
        conn
        |> put_flash(:info, "Payment method created successfully.")
        |> redirect(to: ~p"/payment_methods/#{payment_method}")

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :new, changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    payment_method = Subscriptions.get_payment_method!(conn.assigns.current_scope, id)
    render(conn, :show, payment_method: payment_method)
  end

  def edit(conn, %{"id" => id}) do
    payment_method = Subscriptions.get_payment_method!(conn.assigns.current_scope, id)
    changeset = Subscriptions.change_payment_method(conn.assigns.current_scope, payment_method)
    render(conn, :edit, payment_method: payment_method, changeset: changeset)
  end

  def update(conn, %{"id" => id, "payment_method" => payment_method_params}) do
    payment_method = Subscriptions.get_payment_method!(conn.assigns.current_scope, id)

    case Subscriptions.update_payment_method(conn.assigns.current_scope, payment_method, payment_method_params) do
      {:ok, payment_method} ->
        conn
        |> put_flash(:info, "Payment method updated successfully.")
        |> redirect(to: ~p"/payment_methods/#{payment_method}")

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :edit, payment_method: payment_method, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    payment_method = Subscriptions.get_payment_method!(conn.assigns.current_scope, id)
    {:ok, _payment_method} = Subscriptions.delete_payment_method(conn.assigns.current_scope, payment_method)

    conn
    |> put_flash(:info, "Payment method deleted successfully.")
    |> redirect(to: ~p"/payment_methods")
  end
end
