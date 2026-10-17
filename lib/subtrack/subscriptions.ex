defmodule Subtrack.Subscriptions do
  @moduledoc """
  The Subscriptions context.
  """

  import Ecto.Query, warn: false
  alias Subtrack.Repo

  alias Subtrack.Subscriptions.{PaymentMethod, Subscription}
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

  @doc """
  Subscribes to scoped notifications about any subscription changes.

  The broadcasted messages match the pattern:

    * {:created, %Subscription{}}
    * {:updated, %Subscription{}}
    * {:deleted, %Subscription{}}

  """
  def subscribe_subscriptions(%Scope{} = scope) do
    key = scope.user.id

    Phoenix.PubSub.subscribe(Subtrack.PubSub, "user:#{key}:subscriptions")
  end

  defp broadcast_subscription(%Scope{} = scope, message) do
    key = scope.user.id

    Phoenix.PubSub.broadcast(Subtrack.PubSub, "user:#{key}:subscriptions", message)
  end

  @doc """
  Returns the list of subscriptions.

  ## Examples

      iex> list_subscriptions(scope)
      [%Subscription{}, ...]

  """
  def list_subscriptions(%Scope{} = scope) do
    from(s in Subscription,
      where: s.user_id == ^scope.user.id,
      order_by: [asc: s.next_renewal_on],
      preload: :payment_method
    )
    |> Repo.all()

    # Repo.all_by(Subscription, user_id: scope.user.id)
  end

  @doc """
  Gets a single subscription.

  Raises `Ecto.NoResultsError` if the Subscription does not exist.

  ## Examples

      iex> get_subscription!(scope, 123)
      %Subscription{}

      iex> get_subscription!(scope, 456)
      ** (Ecto.NoResultsError)

  """
  def get_subscription!(%Scope{} = scope, id) do
    Subscription
    |> Repo.get_by!(id: id, user_id: scope.user.id)
    |> Repo.preload(:payment_method)

    # Repo.get_by!(Subscription, id: id, user_id: scope.user.id)
  end

  @doc """
  Creates a subscription.

  ## Examples

      iex> create_subscription(scope, %{field: value})
      {:ok, %Subscription{}}

      iex> create_subscription(scope, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_subscription(%Scope{} = scope, attrs) do
    with {:ok, subscription = %Subscription{}} <-
           %Subscription{}
           |> Subscription.changeset(attrs, scope)
           |> Repo.insert() do
      broadcast_subscription(scope, {:created, subscription})
      {:ok, subscription}
    end
  end

  @doc """
  Updates a subscription.

  ## Examples

      iex> update_subscription(scope, subscription, %{field: new_value})
      {:ok, %Subscription{}}

      iex> update_subscription(scope, subscription, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_subscription(%Scope{} = scope, %Subscription{} = subscription, attrs) do
    true = subscription.user_id == scope.user.id

    with {:ok, subscription = %Subscription{}} <-
           subscription
           |> Subscription.changeset(attrs, scope)
           |> Repo.update() do
      broadcast_subscription(scope, {:updated, subscription})
      {:ok, subscription}
    end
  end

  @doc """
  Deletes a subscription.

  ## Examples

      iex> delete_subscription(scope, subscription)
      {:ok, %Subscription{}}

      iex> delete_subscription(scope, subscription)
      {:error, %Ecto.Changeset{}}

  """
  def delete_subscription(%Scope{} = scope, %Subscription{} = subscription) do
    true = subscription.user_id == scope.user.id

    with {:ok, subscription = %Subscription{}} <-
           Repo.delete(subscription) do
      broadcast_subscription(scope, {:deleted, subscription})
      {:ok, subscription}
    end
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking subscription changes.

  ## Examples

      iex> change_subscription(scope, subscription)
      %Ecto.Changeset{data: %Subscription{}}

  """
  def change_subscription(%Scope{} = scope, %Subscription{} = subscription, attrs \\ %{}) do
    true = subscription.user_id == scope.user.id

    Subscription.changeset(subscription, attrs, scope)
  end

  alias Subtrack.Subscriptions.Reminder
  alias Subtrack.Accounts.Scope

  @doc """
  Subscribes to scoped notifications about any reminder changes.

  The broadcasted messages match the pattern:

    * {:created, %Reminder{}}
    * {:updated, %Reminder{}}
    * {:deleted, %Reminder{}}

  """
  def subscribe_reminders(%Scope{} = scope) do
    key = scope.user.id

    Phoenix.PubSub.subscribe(Subtrack.PubSub, "user:#{key}:reminders")
  end

  defp broadcast_reminder(%Scope{} = scope, message) do
    key = scope.user.id

    Phoenix.PubSub.broadcast(Subtrack.PubSub, "user:#{key}:reminders", message)
  end

  @doc """
  Returns the list of reminders.

  ## Examples

      iex> list_reminders(scope, subscription)
      [%Reminder{}, ...]

  """

  # def list_reminders(%Scope{} = scope) do
  #   Repo.all_by(Reminder, user_id: scope.user.id)
  # end

  def list_reminders(%Scope{} = scope, %Subscription{} = subscription) do
    from(
      r in Reminder,
      where: r.user_id == ^scope.user.id and r.subscription_id == ^subscription.id,
      order_by: [desc: r.days_before, asc: r.send_at]
    )
    |> Repo.all()
  end

  @doc """
  Gets a single reminder.

  Raises `Ecto.NoResultsError` if the Reminder does not exist.

  ## Examples

      iex> get_reminder!(scope, 321, 123)
      %Reminder{}

      iex> get_reminder!(scope, 654, 456)
      ** (Ecto.NoResultsError)

  """

  # def get_reminder!(%Scope{} = scope, id) do
  #   Repo.get_by!(Reminder, id: id, user_id: scope.user.id)
  # end

  def get_reminder!(%Scope{} = scope, %Subscription{} = subscription, id) do
    Repo.get_by!(Reminder, id: id, subscription_id: subscription.id, user_id: scope.user.id)
  end

  @doc """
  Creates a reminder.

  ## Examples

      iex> create_reminder(scope, subscription, %{field: value})
      {:ok, %Reminder{}}

      iex> create_reminder(scope, subscription, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """

  # def create_reminder(%Scope{} = scope, attrs) do
  #   with {:ok, reminder = %Reminder{}} <-
  #          %Reminder{}
  #          |> Reminder.changeset(attrs, scope)
  #          |> Repo.insert() do
  #     broadcast_reminder(scope, {:created, reminder})
  #     {:ok, reminder}
  #   end
  # end

  def create_reminder(%Scope{} = scope, %Subscription{} = subscription, attrs) do
    true = subscription.user_id == scope.user.id

    with {:ok, reminder = %Reminder{}} <-
           %Reminder{subscription_id: subscription.id}
           |> Reminder.changeset(attrs, scope)
           |> Repo.insert() do
      broadcast_reminder(scope, {:created, reminder})
      {:ok, reminder}
    end
  end

  @doc """
  Updates a reminder.

  ## Examples

      iex> update_reminder(scope, reminder, %{field: new_value})
      {:ok, %Reminder{}}

      iex> update_reminder(scope, reminder, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_reminder(%Scope{} = scope, %Reminder{} = reminder, attrs) do
    true = reminder.user_id == scope.user.id

    with {:ok, reminder = %Reminder{}} <-
           reminder
           |> Reminder.changeset(attrs, scope)
           |> Repo.update() do
      broadcast_reminder(scope, {:updated, reminder})
      {:ok, reminder}
    end
  end

  @doc """
  Deletes a reminder.

  ## Examples

      iex> delete_reminder(scope, reminder)
      {:ok, %Reminder{}}

      iex> delete_reminder(scope, reminder)
      {:error, %Ecto.Changeset{}}

  """
  def delete_reminder(%Scope{} = scope, %Reminder{} = reminder) do
    true = reminder.user_id == scope.user.id

    with {:ok, reminder = %Reminder{}} <-
           Repo.delete(reminder) do
      broadcast_reminder(scope, {:deleted, reminder})
      {:ok, reminder}
    end
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking reminder changes.

  ## Examples

      iex> change_reminder(scope, reminder)
      %Ecto.Changeset{data: %Reminder{}}

  """
  def change_reminder(%Scope{} = scope, %Reminder{} = reminder, attrs \\ %{}) do
    true = reminder.user_id == scope.user.id

    Reminder.changeset(reminder, attrs, scope)
  end
end
