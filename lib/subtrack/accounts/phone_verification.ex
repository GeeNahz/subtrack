defmodule Subtrack.Accounts.PhoneVerification do
  use Ecto.Schema

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "phone_verifications" do
    field :phone_number, :string
    field :code_hash, :string
    field :attempts, :integer, default: 0
    field :expires_at, :utc_datetime
    field :sent_at, :utc_datetime

    belongs_to :user, Subtrack.Accounts.User

    timestamps(type: :utc_datetime)
  end
end
