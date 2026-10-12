defmodule Subtrack.Accounts.Profile do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "profiles" do
    field :first_name, :string
    field :last_name, :string
    field :username, :string

    belongs_to :user, Subtrack.Accounts.User

    timestamps(type: :utc_datetime)
  end

  def changeset(profile, attrs) do
    profile
    |> cast(attrs, [:first_name, :last_name, :username])
    |> validate_required([:first_name])
    |> validate_length(:username, min: 3, max: 30)
    |> validate_format(:username, ~r/^[a-zA-Z0-9_]+$/,
      message: "letters, numbers, and underscores only"
    )
    |> unique_constraint(:username)
  end
end
