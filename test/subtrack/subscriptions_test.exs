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
end
