defmodule Subtrack.Subscriptions.Subscription do
  use Ecto.Schema
  import Ecto.Changeset

  import Ecto.Query
  alias Subtrack.Repo
  alias Subtrack.Subscriptions.{PaymentMethod, BillingCycles}

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "subscriptions" do
    field :name, :string
    field :plan_name, :string
    field :amount, :decimal
    field :fee_amount, :decimal, default: Decimal.new(0)
    field :currency, :string
    field :fx_rate, :decimal
    field :billing_cycle, Ecto.Enum, values: BillingCycles.all()
    field :billing_anchor_on, :date
    field :next_renewal_on, :date
    field :status, Ecto.Enum, values: [:active, :paused, :cancelled], default: :active
    field :manage_url, :string
    field :notes, :string

    field :user_id, :binary_id
    belongs_to :payment_method, Subtrack.Subscriptions.PaymentMethod
    has_many :reminders, Subtrack.Subscriptions.Reminder

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(subscription, attrs, user_scope) do
    subscription
    |> cast(attrs, [
      :name,
      :plan_name,
      :amount,
      :fee_amount,
      :currency,
      :fx_rate,
      :billing_cycle,
      :next_renewal_on,
      :status,
      :manage_url,
      :notes,
      :payment_method_id
    ])
    |> validate_required([
      :name,
      :amount,
      :fee_amount,
      :currency,
      :billing_cycle,
      :next_renewal_on
    ])
    |> validate_inclusion(:currency, Subtrack.Currencies.codes())
    |> validate_number(:amount, greater_than: 0)
    |> validate_number(:fee_amount, greater_than_or_equal_to: 0)
    |> validate_number(:fx_rate, greater_than: 0)
    |> validate_payment_method_owner(user_scope)
    |> sync_anchor()
    |> put_change(:user_id, user_scope.user.id)
  end

  def validate_payment_method_owner(changeset, user_scope) do
    validate_change(changeset, :payment_method_id, fn :payment_method_id, id ->
      owned? =
        Repo.exists?(
          from p in PaymentMethod, where: p.id == ^id and p.user_id == ^user_scope.user.id
        )

      if owned?, do: [], else: [payment_method_id: "is not one of your payment methods"]
    end)
  end

  # fee_amount is in the billing currency (same as `currency`)
  def total_amount(%__MODULE__{amount: a, fee_amount: f}), do: Decimal.add(a, f)

  # Requires :payment_method to be preloaded. No FX rate, no card, or a card
  # in the same currency as the plain all mean "nothing to convert".
  def estimated_card_charge(%__MODULE__{fx_rate: nil}), do: nil

  def estimated_card_charge(%__MODULE__{
        payment_method: %PaymentMethod{currency: c},
        currency: c
      }),
      do: nil

  def estimated_card_charge(%__MODULE__{payment_method: %PaymentMethod{}, fx_rate: rate} = sub) do
    sub |> total_amount() |> Decimal.mult(rate) |> Decimal.round(2)
  end

  def estimated_card_charge(_), do: nil

  defp sync_anchor(changeset) do
    date_changed? = Map.has_key?(changeset.changes, :next_renewal_on)
    cycle_changed? = Map.has_key?(changeset.changes, :billing_cycle)
    missing? = is_nil(get_field(changeset, :billing_anchor_on))

    case get_field(changeset, :next_renewal_on) do
      %Date{} = date when date_changed? or cycle_changed? or missing? ->
        put_change(changeset, :billing_anchor_on, date)

      _ ->
        changeset
    end
  end
end
