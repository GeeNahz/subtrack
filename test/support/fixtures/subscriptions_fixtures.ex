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
end
