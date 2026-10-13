defmodule Subtrack.Subscriptions.PaymentMethod do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "payment_methods" do
    field :nickname, :string
    field :brand, Ecto.Enum, values: [:visa, :mastercard, :verve, :amex, :other]
    field :card_mode, Ecto.Enum, values: [:physical, :virtual]
    field :currency, :string
    field :last4, :string
    field :bank_name, :string
    field :expiry_month, :integer
    field :expiry_year, :integer
    field :user_id, :binary_id

    # belongs_to :users, Subtrack.Accounts.User

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(payment_method, attrs, user_scope) do
    payment_method
    |> cast(attrs, [
      :nickname,
      :brand,
      :card_mode,
      :currency,
      :last4,
      :bank_name,
      :expiry_month,
      :expiry_year
    ])
    |> validate_required([
      :brand,
      :card_mode,
      :currency,
      :last4
    ])
    |> update_change(:currency, &String.upcase/1)
    |> validate_length(:currency, is: 3)
    |> validate_format(:last4, ~r/^\d{4}$/, message: "must be exactly 4 digits")
    |> validate_number(:expiry_month, greater_than_or_equal_to: 1, less_than_or_equal_to: 12)
    |> validate_number(:expiry_year, greater_than_or_equal_to: 2000, less_than_or_equal_to: 2100)
    |> put_change(:user_id, user_scope.user.id)
  end
end
