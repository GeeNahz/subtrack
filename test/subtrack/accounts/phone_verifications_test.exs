defmodule Subtrack.Accounts.PhoneVerificationsTest do
  use Subtrack.DataCase

  import Subtrack.AccountsFixtures

  alias Subtrack.Accounts
  alias Subtrack.Accounts.PhoneVerification

  @phone "+2348012345678"

  defp scope_with_phone(phone \\ @phone) do
    scope = user_scope_fixture()
    {:ok, user} = Accounts.update_user_contact(scope, %{"phone_number" => phone})
    %{scope | user: user}
  end

  defp sent_code do
    assert_received {:sms, _to, body}
    [code] = Regex.run(~r/\d{6}/, body)
    code
  end

  test "a correct code verifies the number" do
    scope = scope_with_phone()
    assert {:ok, :sent} = Accounts.start_phone_verification(scope)

    assert {:ok, user} = Accounts.confirm_phone(scope, sent_code())
    assert user.phone_confirmed_at
    assert Repo.aggregate(PhoneVerification, :count) == 0
  end

  test "five wrong guesses lock the code, even if the right one follows" do
    scope = scope_with_phone()
    {:ok, :sent} = Accounts.start_phone_verification(scope)
    code = sent_code()
    wrong = if code == "000000", do: "000001", else: "000000"

    for _ <- 1..5, do: assert({:error, :invalid_code} = Accounts.confirm_phone(scope, wrong))
    assert {:error, :too_many_attempts} = Accounts.confirm_phone(scope, code)
  end

  test "an immediate resend is rejected" do
    scope = scope_with_phone()
    assert {:ok, :sent} = Accounts.start_phone_verification(scope)
    assert {:error, {:cooldown, seconds}} = Accounts.start_phone_verification(scope)
    assert seconds > 0
  end

  test "an expired code is rejected" do
    scope = scope_with_phone()
    {:ok, :sent} = Accounts.start_phone_verification(scope)
    code = sent_code()

    past = DateTime.add(DateTime.utc_now(:second), -1)
    Repo.update_all(PhoneVerification, set: [expires_at: past])

    assert {:error, :expired} = Accounts.confirm_phone(scope, code)
  end

  test "changing the number invalidates a pending code" do
    scope = scope_with_phone()
    {:ok, :sent} = Accounts.start_phone_verification(scope)
    code = sent_code()

    {:ok, user} = Accounts.update_user_contact(scope, %{"phone_number" => "+23480999999999"})
    assert {:error, :no_code} = Accounts.confirm_phone(%{scope | user: user}, code)
  end

  test "a failed SMS leaves no pending code and no cooldown" do
    scope = scope_with_phone()
    Process.put(:sms_result, {:error, :provider_down})

    assert {:error, :sms_failed} = Accounts.start_phone_verification(scope)
    assert Repo.aggregate(PhoneVerification, :count) == 0

    Process.delete(:sms_result)
    assert {:ok, :sent} = Accounts.start_phone_verification(scope)
  end

  test "unverified numbers can repeat, and a newer verification takes the number" do
    a = scope_with_phone()
    b = scope_with_phone()

    {:ok, :sent} = Accounts.start_phone_verification(a)
    {:ok, _} = Accounts.confirm_phone(a, sent_code())

    {:ok, :sent} = Accounts.start_phone_verification(b)
    {:ok, _} = Accounts.confirm_phone(b, sent_code())

    assert Repo.reload!(a.user).phone_confirmed_at == nil
    assert Repo.reload!(b.user).phone_confirmed_at
  end
end
