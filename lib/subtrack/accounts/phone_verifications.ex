defmodule Subtrack.Accounts.PhoneVerifications do
  import Ecto.Query, warn: false

  alias Subtrack.{Repo, SMS}
  alias Subtrack.Accounts.{PhoneVerification, Scope, User}

  @ttl_seconds 10 * 60
  @cooldown_seconds 60
  @max_attempts 5

  # --- Sending ------------

  @doc """
  Returns {:ok, :sent} or {:error, reason} where reason is
  :no_phone | :already_verified | {:cooldown, seconds} | :sms_failed
  """
  def start(%Scope{user: user}) do
    cond do
      is_nil(user.phone_number) -> {:error, :no_phone}
      user.phone_confirmed_at -> {:error, :already_verified}
      true -> send_code(user)
    end
  end

  defp send_code(user) do
    now = DateTime.utc_now(:second)
    code = generate_code()

    with :ok <- check_cooldown(user, now),
         {:ok, _row} <- store(user, code, now),
         :ok <- text_code(user, code) do
      {:ok, :sent}
    else
      {:error, {:cooldown, _seconds}} = error ->
        error

      {:error, :sms_failed} ->
        # Don't leave the user stuck in a cooldown for a code that never left.
        Repo.delete_all(from v in PhoneVerification, where: v.user_id == ^user.id)
        {:error, :sms_failed}
    end
  end

  defp check_cooldown(user, now) do
    case Repo.get_by(PhoneVerification, user_id: user.id) do
      nil ->
        :ok

      %{sent_at: sent_at} ->
        wait = @cooldown_seconds - DateTime.diff(now, sent_at)
        if wait > 0, do: {:error, {:cooldown, wait}}, else: :ok
    end
  end

  defp store(user, code, now) do
    Repo.insert(
      %PhoneVerification{
        user_id: user.id,
        phone_number: user.phone_number,
        code_hash: hash(user.id, user.phone_number, code),
        attempts: 0,
        sent_at: now,
        expires_at: DateTime.add(now, @ttl_seconds)
      },
      on_conflict:
        {:replace, [:phone_number, :code_hash, :attempts, :sent_at, :expires_at, :updated_at]},
      conflict_target: :user_id
    )
  end

  defp text_code(user, code) do
    case SMS.deliver(
           user.phone_number,
           "Your Subtrack verification code is #{code}. It expires in 10 minutes."
         ) do
      {:ok, _ref} -> :ok
      {:error, _reason} -> {:error, :sms_failed}
      {:permanent, _reason} -> {:error, :sms_failed}
    end
  end

  # --- Confirming ------------

  @doc """
  Returns {:ok, user} or {:error, reason} where reason is
  :no_code | :expired | :too_many_attempts | :invalid_code | %Ecto.Changeset{}
  """
  def confirm(%Scope{user: user}, code) when is_binary(code) do
    # Count the attemps first, atomically, so parallel guesses can't beat the cap.
    {_count, rows} =
      from(v in PhoneVerification, where: v.user_id == ^user.id, select: v)
      |> Repo.update_all(inc: [attempts: 1])

    case rows do
      [] -> {:error, :no_code}
      [verification] -> check(verification, user, String.trim(code), DateTime.utc_now(:second))
    end
  end

  defp check(v, user, code, now) do
    cond do
      v.attempts > @max_attempts -> {:error, :too_many_attempts}
      DateTime.compare(v.expires_at, now) != :gt -> {:error, :expired}
      v.phone_number != user.phone_number -> {:error, :no_code}
      not valid_code?(v, user, code) -> {:error, :invalid_code}
      true -> mark_verified(v, user)
    end
  end

  defp valid_code?(v, user, code) do
    Plug.Crypto.secure_compare(v.code_hash, hash(user.id, v.phone_number, code))
  end

  # Newest verification wins: take the number off any other account first.
  # Order matters, or the partial unique index would reject our own update.
  defp mark_verified(verification, user) do
    Repo.transaction(fn ->
      from(u in User,
        where:
          u.phone_number == ^user.phone_number and u.id != ^user.id and
            not is_nil(u.phone_confirmed_at)
      )
      |> Repo.update_all(set: [phone_confirmed_at: nil, updated_at: DateTime.utc_now(:second)])

      case user |> User.phone_verified_changeset() |> Repo.update() do
        {:ok, updated} ->
          Repo.delete!(verification)
          updated

        {:error, changeset} ->
          Repo.rollback(changeset)
      end
    end)
  end

  # --- Helpers ------------

  # :crypto.strong_rand_bytes is cryptographically secure; Enum.random/1 is not.
  defp generate_code do
    :crypto.strong_rand_bytes(4)
    |> :binary.decode_unsigned()
    |> rem(1_000_000)
    |> Integer.to_string()
    |> String.pad_leading(6, "0")
  end

  defp hash(user_id, phone, code) do
    :crypto.mac(:hmac, :sha256, secret(), "#{user_id}:#{phone}:#{code}")
    |> Base.encode16(case: :lower)
  end

  defp secret do
    Application.fetch_env!(:subtrack, SubtrackWeb.Endpoint)[:secret_key_base]
  end
end
