defmodule Subtrack.Subscriptions do
  @moduledoc """
  The Subscriptions context.
  """

  import Ecto.Query, warn: false
  alias Subtrack.Repo

  alias Subtrack.Subscriptions.PaymentMethod
  alias Subtrack.Accounts.Scope

  @doc """
  Subscribes to scoped notifications about any payment_method changes.

  The broadcasted messages match the pattern:

    * {:created, %PaymentMethod{}}
    * {:updated, %PaymentMethod{}}
    * {:deleted, %PaymentMethod{}}

  """
  def subscribe_payment_methods(%Scope{} = scope) do
    key = scope.user.id

    Phoenix.PubSub.subscribe(Subtrack.PubSub, "user:#{key}:payment_methods")
  end

  defp broadcast_payment_method(%Scope{} = scope, message) do
    key = scope.user.id

    Phoenix.PubSub.broadcast(Subtrack.PubSub, "user:#{key}:payment_methods", message)
  end

  @doc """
  Returns the list of payment_methods.

  ## Examples

      iex> list_payment_methods(scope)
      [%PaymentMethod{}, ...]

  """
  def list_payment_methods(%Scope{} = scope) do
    Repo.all_by(PaymentMethod, user_id: scope.user.id)
  end

  @doc """
  Gets a single payment_method.

  Raises `Ecto.NoResultsError` if the Payment method does not exist.

  ## Examples

      iex> get_payment_method!(scope, 123)
      %PaymentMethod{}

      iex> get_payment_method!(scope, 456)
      ** (Ecto.NoResultsError)

  """
  def get_payment_method!(%Scope{} = scope, id) do
    Repo.get_by!(PaymentMethod, id: id, user_id: scope.user.id)
  end

  @doc """
  Creates a payment_method.

  ## Examples

      iex> create_payment_method(scope, %{field: value})
      {:ok, %PaymentMethod{}}

      iex> create_payment_method(scope, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_payment_method(%Scope{} = scope, attrs) do
    with {:ok, payment_method = %PaymentMethod{}} <-
           %PaymentMethod{}
           |> PaymentMethod.changeset(attrs, scope)
           |> Repo.insert() do
      broadcast_payment_method(scope, {:created, payment_method})
      {:ok, payment_method}
    end
  end

  @doc """
  Updates a payment_method.

  ## Examples

      iex> update_payment_method(scope, payment_method, %{field: new_value})
      {:ok, %PaymentMethod{}}

      iex> update_payment_method(scope, payment_method, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_payment_method(%Scope{} = scope, %PaymentMethod{} = payment_method, attrs) do
    true = payment_method.user_id == scope.user.id

    with {:ok, payment_method = %PaymentMethod{}} <-
           payment_method
           |> PaymentMethod.changeset(attrs, scope)
           |> Repo.update() do
      broadcast_payment_method(scope, {:updated, payment_method})
      {:ok, payment_method}
    end
  end

  @doc """
  Deletes a payment_method.

  ## Examples

      iex> delete_payment_method(scope, payment_method)
      {:ok, %PaymentMethod{}}

      iex> delete_payment_method(scope, payment_method)
      {:error, %Ecto.Changeset{}}

  """
  def delete_payment_method(%Scope{} = scope, %PaymentMethod{} = payment_method) do
    true = payment_method.user_id == scope.user.id

    with {:ok, payment_method = %PaymentMethod{}} <-
           Repo.delete(payment_method) do
      broadcast_payment_method(scope, {:deleted, payment_method})
      {:ok, payment_method}
    end
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking payment_method changes.

  ## Examples

      iex> change_payment_method(scope, payment_method)
      %Ecto.Changeset{data: %PaymentMethod{}}

  """
  def change_payment_method(%Scope{} = scope, %PaymentMethod{} = payment_method, attrs \\ %{}) do
    true = payment_method.user_id == scope.user.id

    PaymentMethod.changeset(payment_method, attrs, scope)
  end
end
