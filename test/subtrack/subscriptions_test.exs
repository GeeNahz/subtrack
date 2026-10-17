defmodule Subtrack.SubscriptionsTest do
  use Subtrack.DataCase

  alias Subtrack.Subscriptions

  describe "payment_methods" do
    alias Subtrack.Subscriptions.PaymentMethod

    import Subtrack.AccountsFixtures, only: [user_scope_fixture: 0]
    import Subtrack.SubscriptionsFixtures

    @invalid_attrs %{
      currency: nil,
      nickname: nil,
      brand: nil,
      card_mode: nil,
      last4: nil,
      bank_name: nil,
      expiry_month: nil,
      expiry_year: nil
    }

    test "list_payment_methods/1 returns all scoped payment_methods" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      payment_method = payment_method_fixture(scope)
      other_payment_method = payment_method_fixture(other_scope)
      assert Subscriptions.list_payment_methods(scope) == [payment_method]
      assert Subscriptions.list_payment_methods(other_scope) == [other_payment_method]
    end

    test "get_payment_method!/2 returns the payment_method with given id" do
      scope = user_scope_fixture()
      payment_method = payment_method_fixture(scope)
      other_scope = user_scope_fixture()
      assert Subscriptions.get_payment_method!(scope, payment_method.id) == payment_method

      assert_raise Ecto.NoResultsError, fn ->
        Subscriptions.get_payment_method!(other_scope, payment_method.id)
      end
    end

    test "create_payment_method/2 with valid data creates a payment_method" do
      valid_attrs = %{
        currency: "NGN",
        nickname: "some nickname",
        brand: :visa,
        card_mode: :physical,
        last4: "8933",
        bank_name: "some bank_name",
        expiry_month: 5,
        expiry_year: 2030
      }

      scope = user_scope_fixture()

      assert {:ok, %PaymentMethod{} = payment_method} =
               Subscriptions.create_payment_method(scope, valid_attrs)

      assert payment_method.currency == "NGN"
      assert payment_method.nickname == "some nickname"
      assert payment_method.brand == :visa
      assert payment_method.card_mode == :physical
      assert payment_method.last4 == "8933"
      assert payment_method.bank_name == "some bank_name"
      assert payment_method.expiry_month == 5
      assert payment_method.expiry_year == 2030
      assert payment_method.user_id == scope.user.id
    end

    test "create_payment_method/2 with invalid data returns error changeset" do
      scope = user_scope_fixture()

      assert {:error, %Ecto.Changeset{}} =
               Subscriptions.create_payment_method(scope, @invalid_attrs)
    end

    test "update_payment_method/3 with valid data updates the payment_method" do
      scope = user_scope_fixture()
      payment_method = payment_method_fixture(scope)

      update_attrs = %{
        currency: "EUR",
        nickname: "some updated nickname",
        brand: :mastercard,
        card_mode: :virtual,
        last4: "3783",
        bank_name: "some updated bank_name",
        expiry_month: 1,
        expiry_year: 2029
      }

      assert {:ok, %PaymentMethod{} = payment_method} =
               Subscriptions.update_payment_method(scope, payment_method, update_attrs)

      assert payment_method.currency == "EUR"
      assert payment_method.nickname == "some updated nickname"
      assert payment_method.brand == :mastercard
      assert payment_method.card_mode == :virtual
      assert payment_method.last4 == "3783"
      assert payment_method.bank_name == "some updated bank_name"
      assert payment_method.expiry_month == 1
      assert payment_method.expiry_year == 2029
    end

    test "update_payment_method/3 with invalid scope raises" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      payment_method = payment_method_fixture(scope)

      assert_raise MatchError, fn ->
        Subscriptions.update_payment_method(other_scope, payment_method, %{})
      end
    end

    test "update_payment_method/3 with invalid data returns error changeset" do
      scope = user_scope_fixture()
      payment_method = payment_method_fixture(scope)

      assert {:error, %Ecto.Changeset{}} =
               Subscriptions.update_payment_method(scope, payment_method, @invalid_attrs)

      assert payment_method == Subscriptions.get_payment_method!(scope, payment_method.id)
    end

    test "delete_payment_method/2 deletes the payment_method" do
      scope = user_scope_fixture()
      payment_method = payment_method_fixture(scope)
      assert {:ok, %PaymentMethod{}} = Subscriptions.delete_payment_method(scope, payment_method)

      assert_raise Ecto.NoResultsError, fn ->
        Subscriptions.get_payment_method!(scope, payment_method.id)
      end
    end

    test "delete_payment_method/2 with invalid scope raises" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      payment_method = payment_method_fixture(scope)

      assert_raise MatchError, fn ->
        Subscriptions.delete_payment_method(other_scope, payment_method)
      end
    end

    test "change_payment_method/2 returns a payment_method changeset" do
      scope = user_scope_fixture()
      payment_method = payment_method_fixture(scope)
      assert %Ecto.Changeset{} = Subscriptions.change_payment_method(scope, payment_method)
    end
  end

  describe "subscriptions" do
    alias Subtrack.Subscriptions.{Subscription, PaymentMethod}

    import Subtrack.AccountsFixtures, only: [user_scope_fixture: 0]
    import Subtrack.SubscriptionsFixtures

    @invalid_attrs %{
      name: nil,
      status: nil,
      currency: nil,
      amount: nil,
      plan_name: nil,
      fee_amount: nil,
      fx_rate: nil,
      billing_cycle: nil,
      next_renewal_on: nil,
      manage_url: nil,
      notes: nil
    }

    test "list_subscriptions/1 returns all scoped subscriptions" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      subscription = subscription_fixture(scope)
      other_subscription = subscription_fixture(other_scope)
      assert Subscriptions.list_subscriptions(scope) == [subscription]
      assert Subscriptions.list_subscriptions(other_scope) == [other_subscription]
    end

    test "get_subscription!/2 returns the subscription with given id" do
      scope = user_scope_fixture()
      subscription = subscription_fixture(scope)
      other_scope = user_scope_fixture()
      assert Subscriptions.get_subscription!(scope, subscription.id) == subscription

      assert_raise Ecto.NoResultsError, fn ->
        Subscriptions.get_subscription!(other_scope, subscription.id)
      end
    end

    test "create_subscription/2 with valid data creates a subscription" do
      valid_attrs = %{
        name: "some name",
        status: :active,
        currency: "GBP",
        amount: "120.5",
        plan_name: "some plan_name",
        fee_amount: "120.5",
        fx_rate: "120.5",
        billing_cycle: :weekly,
        next_renewal_on: ~D[2026-10-12],
        manage_url: "some manage_url",
        notes: "some notes"
      }

      scope = user_scope_fixture()

      assert {:ok, %Subscription{} = subscription} =
               Subscriptions.create_subscription(scope, valid_attrs)

      assert subscription.name == "some name"
      assert subscription.status == :active
      assert subscription.currency == "GBP"
      assert subscription.amount == Decimal.new("120.5")
      assert subscription.plan_name == "some plan_name"
      assert subscription.fee_amount == Decimal.new("120.5")
      assert subscription.fx_rate == Decimal.new("120.5")
      assert subscription.billing_cycle == :weekly
      assert subscription.next_renewal_on == ~D[2026-10-12]
      assert subscription.manage_url == "some manage_url"
      assert subscription.notes == "some notes"
      assert subscription.user_id == scope.user.id
    end

    test "create_subscription/2 with invalid data returns error changeset" do
      scope = user_scope_fixture()

      assert {:error, %Ecto.Changeset{}} =
               Subscriptions.create_subscription(scope, @invalid_attrs)
    end

    test "update_subscription/3 with valid data updates the subscription" do
      scope = user_scope_fixture()
      subscription = subscription_fixture(scope)

      update_attrs = %{
        name: "some updated name",
        status: :paused,
        currency: "GBP",
        amount: "456.7",
        plan_name: "some updated plan_name",
        fee_amount: "456.7",
        fx_rate: "456.7",
        billing_cycle: :monthly,
        next_renewal_on: ~D[2026-10-13],
        manage_url: "some updated manage_url",
        notes: "some updated notes"
      }

      assert {:ok, %Subscription{} = subscription} =
               Subscriptions.update_subscription(scope, subscription, update_attrs)

      assert subscription.name == "some updated name"
      assert subscription.status == :paused
      assert subscription.currency == "GBP"
      assert subscription.amount == Decimal.new("456.7")
      assert subscription.plan_name == "some updated plan_name"
      assert subscription.fee_amount == Decimal.new("456.7")
      assert subscription.fx_rate == Decimal.new("456.7")
      assert subscription.billing_cycle == :monthly
      assert subscription.next_renewal_on == ~D[2026-10-13]
      assert subscription.manage_url == "some updated manage_url"
      assert subscription.notes == "some updated notes"
    end

    test "update_subscription/3 with invalid scope raises" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      subscription = subscription_fixture(scope)

      assert_raise MatchError, fn ->
        Subscriptions.update_subscription(other_scope, subscription, %{})
      end
    end

    test "update_subscription/3 with invalid data returns error changeset" do
      scope = user_scope_fixture()
      subscription = subscription_fixture(scope)

      assert {:error, %Ecto.Changeset{}} =
               Subscriptions.update_subscription(scope, subscription, @invalid_attrs)

      assert subscription == Subscriptions.get_subscription!(scope, subscription.id)
    end

    test "delete_subscription/2 deletes the subscription" do
      scope = user_scope_fixture()
      subscription = subscription_fixture(scope)
      assert {:ok, %Subscription{}} = Subscriptions.delete_subscription(scope, subscription)

      assert_raise Ecto.NoResultsError, fn ->
        Subscriptions.get_subscription!(scope, subscription.id)
      end
    end

    test "delete_subscription/2 with invalid scope raises" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      subscription = subscription_fixture(scope)

      assert_raise MatchError, fn ->
        Subscriptions.delete_subscription(other_scope, subscription)
      end
    end

    test "change_subscription/2 returns a subscription changeset" do
      scope = user_scope_fixture()
      subscription = subscription_fixture(scope)
      assert %Ecto.Changeset{} = Subscriptions.change_subscription(scope, subscription)
    end

    test "create_subscription/2 rejects another user's payment method" do
      scope = user_scope_fixture()
      other_pm = payment_method_fixture(user_scope_fixture())

      attrs = %{
        name: "Netflix",
        amount: "15.99",
        fee_amount: "0",
        currency: "NGN",
        billing_cycle: :monthly,
        next_renewal_on: ~D[2026-11-01],
        payment_method_id: other_pm.id
      }

      assert {:error, changeset} = Subscriptions.create_subscription(scope, attrs)
      assert %{payment_method_id: ["is not one of your payment methods"]} = errors_on(changeset)
    end

    test "estimated_card_charge/1 converts with the fx rate" do
      sub = %Subscription{
        amount: Decimal.new("15.00"),
        fee_amount: Decimal.new("0.99"),
        currency: "USD",
        fx_rate: Decimal.new("1600"),
        payment_method: %PaymentMethod{currency: "NGN"}
      }

      assert Decimal.equal?(Subscription.estimated_card_charge(sub), Decimal.new("25584.00"))
    end

    test "estimated_card_charge/1 is nil when card and plan currency match" do
      sub = %Subscription{
        amount: Decimal.new("5000"),
        fee_amount: Decimal.new("0"),
        currency: "NGN",
        fx_rate: Decimal.new("1"),
        payment_method: %PaymentMethod{currency: "NGN"}
      }

      assert Subscription.estimated_card_charge(sub) == nil
    end
  end

  describe "reminders" do
    alias Subtrack.Subscriptions.Reminder

    import Subtrack.AccountsFixtures, only: [user_scope_fixture: 0]
    import Subtrack.SubscriptionsFixtures

    @invalid_attrs %{enabled: nil, days_before: nil, send_at: nil, channels: nil}

    test "list_reminders/1 returns all scoped reminders" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      subscription = subscription_fixture(scope)
      other_subscription = subscription_fixture(other_scope)
      reminder = reminder_fixture(scope, %{subscription: subscription})
      other_reminder = reminder_fixture(other_scope, %{subscription: other_subscription})
      assert Subscriptions.list_reminders(scope, subscription) == [reminder]
      assert Subscriptions.list_reminders(other_scope, other_subscription) == [other_reminder]
    end

    test "get_reminder!/2 returns the reminder with given id" do
      scope = user_scope_fixture()
      subscription = subscription_fixture(scope)
      reminder = reminder_fixture(scope, %{subscription: subscription})
      other_scope = user_scope_fixture()
      other_subscription = subscription_fixture(other_scope)
      assert Subscriptions.get_reminder!(scope, subscription, reminder.id) == reminder

      assert_raise Ecto.NoResultsError, fn ->
        Subscriptions.get_reminder!(other_scope, other_subscription, reminder.id)
      end
    end

    test "create_reminder/2 with valid data creates a reminder" do
      valid_attrs = %{
        enabled: true,
        days_before: 42,
        send_at: ~T[14:00:00],
        channels: [:email]
      }

      scope = user_scope_fixture()
      subscription = subscription_fixture(scope)

      assert {:ok, %Reminder{} = reminder} =
               Subscriptions.create_reminder(scope, subscription, valid_attrs)

      assert reminder.enabled == true
      assert reminder.days_before == 42
      assert reminder.send_at == ~T[14:00:00]
      assert reminder.channels == [:email]
      assert reminder.subscription_id == subscription.id
      assert reminder.user_id == scope.user.id
    end

    test "create_reminder/2 with invalid data returns error changeset" do
      scope = user_scope_fixture()
      subscription = subscription_fixture(scope)

      assert {:error, %Ecto.Changeset{}} =
               Subscriptions.create_reminder(scope, subscription, @invalid_attrs)
    end

    test "update_reminder/3 with valid data updates the reminder" do
      scope = user_scope_fixture()
      subscription = subscription_fixture(scope)
      reminder = reminder_fixture(scope, %{subscription: subscription})

      update_attrs = %{
        enabled: false,
        days_before: 43,
        send_at: ~T[15:01:01],
        channels: [:sms]
      }

      assert {:ok, %Reminder{} = reminder} =
               Subscriptions.update_reminder(scope, reminder, update_attrs)

      assert reminder.enabled == false
      assert reminder.days_before == 43
      assert reminder.send_at == ~T[15:01:01]
      assert reminder.channels == [:sms]
    end

    test "update_reminder/3 with invalid scope raises" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      subscription = subscription_fixture(scope)
      reminder = reminder_fixture(scope, %{subscription: subscription})

      assert_raise MatchError, fn ->
        Subscriptions.update_reminder(other_scope, reminder, %{})
      end
    end

    test "update_reminder/3 with invalid data returns error changeset" do
      scope = user_scope_fixture()
      subscription = subscription_fixture(scope)
      reminder = reminder_fixture(scope, %{subscription: subscription})

      assert {:error, %Ecto.Changeset{}} =
               Subscriptions.update_reminder(scope, reminder, @invalid_attrs)

      assert reminder == Subscriptions.get_reminder!(scope, subscription, reminder.id)
    end

    test "delete_reminder/2 deletes the reminder" do
      scope = user_scope_fixture()
      subscription = subscription_fixture(scope)
      reminder = reminder_fixture(scope, %{subscription: subscription})
      assert {:ok, %Reminder{}} = Subscriptions.delete_reminder(scope, reminder)

      assert_raise Ecto.NoResultsError, fn ->
        Subscriptions.get_reminder!(scope, subscription, reminder.id)
      end
    end

    test "delete_reminder/2 with invalid scope raises" do
      scope = user_scope_fixture()
      subscription = subscription_fixture(scope)
      other_scope = user_scope_fixture()
      reminder = reminder_fixture(scope, %{subscription: subscription})
      assert_raise MatchError, fn -> Subscriptions.delete_reminder(other_scope, reminder) end
    end

    test "change_reminder/2 returns a reminder changeset" do
      scope = user_scope_fixture()
      subscription = subscription_fixture(scope)
      reminder = reminder_fixture(scope, %{subscription: subscription})
      assert %Ecto.Changeset{} = Subscriptions.change_reminder(scope, reminder)
    end

    test "create_reminder/3 rejects a duplicate rule" do
      scope = user_scope_fixture()
      subscription = subscription_fixture(scope)
      attrs = %{days_before: 5, send_at: ~T[10:00:00], channels: [:email]}

      assert {:ok, _} = Subscriptions.create_reminder(scope, subscription, attrs)
      assert {:error, changeset} = Subscriptions.create_reminder(scope, subscription, attrs)
      assert %{days_before: ["you already have a reminder at that time"]} = errors_on(changeset)
      # assert_raise Ecto.ConstraintError, fn ->
      #   Subscriptions.create_reminder(scope, subscription, attrs)
      # end
    end

    test "create_reminder/3 requires a channel and a sane date range" do
      scope = user_scope_fixture()
      subscription = subscription_fixture(scope)

      assert {:error, changeset} =
               Subscriptions.create_reminder(scope, subscription, %{
                 days_before: 91,
                 send_at: ~T[09:00:00],
                 channels: []
               })

      assert %{days_before: [_], channels: [_]} = errors_on(changeset)
    end

    test "create_reminder/3 crashes for someone else's subscription" do
      other_subscription = subscription_fixture(user_scope_fixture())

      assert_raise MatchError, fn ->
        Subscriptions.create_reminder(user_scope_fixture(), other_subscription, %{
          days_before: 1,
          send_at: ~T[08:00:00],
          channels: [:sms]
        })
      end
    end
  end
end
