defmodule Subtrack.SubscriptionsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Subtrack.Subscriptions` context.
  """

  @doc """
  Generate a payment_method.
  """
  def payment_method_fixture(scope, attrs \\ %{}) do
    attrs =
      Enum.into(attrs, %{
        bank_name: "some bank_name",
        brand: :visa,
        card_mode: :physical,
        currency: "NGN",
        expiry_month: 9,
        expiry_year: 2027,
        last4: "1029",
        nickname: "some nickname"
      })

    {:ok, payment_method} = Subtrack.Subscriptions.create_payment_method(scope, attrs)
    payment_method
  end

  @doc """
  Generate a subscription.
  """
  def subscription_fixture(scope, attrs \\ %{}) do
    attrs =
      Enum.into(attrs, %{
        amount: "120.50",
        billing_cycle: :weekly,
        currency: "GBP",
        fee_amount: "120.50",
        fx_rate: "120.500000",
        manage_url: "some manage_url",
        name: "some name",
        next_renewal_on: ~D[2026-10-12],
        notes: "some notes",
        plan_name: "some plan_name",
        status: :active
      })

    {:ok, subscription} = Subtrack.Subscriptions.create_subscription(scope, attrs)
    Subtrack.Repo.preload(subscription, :payment_method)
  end
end
