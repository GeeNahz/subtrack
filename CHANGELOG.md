# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Phoenix 1.8 application scaffold (`Subtrack` / `SubtrackWeb`) with Ecto/Postgres, Tailwind v4, LiveDashboard and Swoosh mailbox preview under `/dev`.
- MIT `LICENSE`.
- Email-based authentication via `phx.gen.auth`: `Accounts.User`, `UserToken`, `Scope`, magic-link log-in, registration, and settings routes (`/users/register`, `/users/log-in`, `/users/settings`).
- `phone_number` (unique), `phone_confirmed_at` and `timezone` (default `Etc/UTC`) columns on `users`.
- `Accounts.Profile` schema (`first_name`, `last_name`, unique `username`), created nested during registration.
- `tzdata` dependency configured as Elixir's time zone database.
- `Subscriptions.PaymentMethod` schema and user-scoped CRUD at `/payment_methods`: brand, physical/virtual card mode, currency, `last4`, bank name and expiry, with format and range validations.
- `Subtrack.Currencies` whitelist (`NGN`, `USD`, `GBP`, `EUR`) used to validate payment method and subscription currencies.
- `Subscriptions.Subscription` schema and user-scoped CRUD at `/subscriptions`: decimal `amount`/`fee_amount`, billing currency, optional `fx_rate`, billing cycle (weekly/monthly/quarterly/yearly), `next_renewal_on`, status (active/paused/cancelled), manage URL, and notes.
- Optional link from a subscription to a payment method (nilified when the card is deleted), with validation that the card belongs to the current user.
- Estimated card charge display (`Subscription.estimated_card_charge/1`), which converts the total (amount + fee) with `fx_rate` when the card currency differs from the billing currency.
- `Subscriptions.Reminder` schema with nested routes `/subscriptions/:id/reminders` (new/create/edit/update/delete): `days_before` (0–90), `send_at` time, delivery channels, enabled flag, and a unique `(subscription_id, days_before, send_at)` constraint.
- Optional `note` (max 200 chars) on reminders.
- Oban job processing (`default` and `notifications` queues, 7-day pruner).
- `reminder_deliveries` log table (`Notifications.ReminderDelivery`) with status `pending`/`sent`/`failed`/`skipped`, plus a unique `(reminder_id, renewal_on, channel)` index so a delivery is claimed at most once.
- `Notifications.Schedule`, which works out each reminder's UTC due time from the user's timezone (handles DST gaps and overlaps) and drops reminders more than 6 hours late.
- `Workers.EnqueueDueReminders` cron sweeper (every 15 minutes) and `Workers.SendReminder` (up to 5 attempts). Sending skips a reminder if it was disabled, the subscription is inactive, or the renewal date changed.
- Stub `Notifications.Dispatcher`, which logs email/SMS reminders instead of sending them.
- Email reminder delivery: `Notifications.ReminderEmail` builds a plain-text reminder (renewal date, total with plan/fee split, estimated card debit, card label, optional note, link to `/subscriptions/:id`) addressed to the user's first name.
- Production mailer on the Resend adapter, configured from `RESEND_API_KEY` and `MAIL_FROM_ADDRESS` in `config/runtime.exs`, with a `:mail_from` sender setting (default `reminders@localhost`) and a `.env.sample`; `.env` files are now git-ignored.
- `Dispatcher.classify_email_error/1`, which treats 4xx responses (except 408 and 429) as permanent and everything else as retryable.
- `Accounts.get_user_with_profile!/1`, which loads a user with their profile preloaded.
- `Subtrack.Money.format/2` for `"NGN 1500.00"`-style amounts.
- Public `Reminder.max_days_before/0`, `Reminder.max_note_length/0` and `Schedule.grace_seconds/0`, so limits are defined in one place.
- `Subscriptions.BillingCycles`, the single list of billing cycles (`weekly`, `monthly`, `quarterly`, `yearly`) with display labels and date maths: occurrences are always computed from an anchor date, so month-end dates clamp (31 Jan → 28 Feb) without drifting (→ 31 Mar).
- `billing_anchor_on` column on `subscriptions` (backfilled from `next_renewal_on`, then `NOT NULL`); it is reset whenever the renewal date or billing cycle is edited.
- `Subscriptions.Renewals` and the `Workers.RollRenewals` cron job (minute 10 of every 6th hour), which move an active subscription's `next_renewal_on` to the next cycle date once the user's local date is more than a day past it. The update is guarded on the old date, so a concurrent user edit wins.
- Profile settings page at `GET`/`PUT /settings/profile` (`ProfileSettingsController`) to edit first name, last name and username, backed by `Accounts.get_profile!/1`, `change_profile/2` and `update_profile/2`.
- Contact settings page at `GET`/`PUT /settings/contact` (`ContactSettingsController`) to edit timezone and mobile number, backed by `Accounts.change_user_contact/2` and `update_user_contact/2`. It warns when the saved number is not yet verified.
- `SettingsComponents.settings_nav/1` tab bar linking Account, Profile and "Contact & timezone" settings.
- `Subtrack.Timezones` with a sorted timezone dropdown list (canonical zones plus `Etc/UTC`) and validation that also accepts legacy aliases such as `Asia/Calcutta`.
- Mobile number verification by SMS code (`Accounts.PhoneVerifications`, `phone_verifications` table, `Accounts.start_phone_verification/1`, `Accounts.confirm_phone/2`) at `GET /settings/phone/verify`, `POST /settings/phone/verify/send` and `POST /settings/phone/verify`. Codes are 6 digits, stored as an HMAC, valid for 10 minutes, limited to 5 attempts and one resend per 60 seconds; a new code replaces the pending one.
- `Subtrack.SMS` behaviour with `SMS.Log` (dev, logs the message) and `SMS.Test` (sends `{:sms, to, body}` to the test process) adapters, selected by the `:sms_adapter` setting.
- `Notifications.ReminderSms`, which builds a short SMS reminder (name, when it renews, date, total amount, optional note).

### Changed
- Subscription detail page lists the subscription's reminders, with their notes.
- Reminder and delivery channel options now come from a single `Notifications.Channels.all/0` list (`email`, `sms`), not hard-coded lists.
- `Dispatcher.deliver/4` sends the `email` channel through `Swoosh` (the `sms` channel is still a logging stub); it returns `{:ok, ref}`, `{:error, reason}` for retryable failures, or `{:permanent, reason}`.
- `Workers.SendReminder` records `{:permanent, reason}` as a final failure and cancels the job instead of retrying, and loads the user with their profile.
- `Notifications.get_delivery/1` also preloads the subscription's payment method.
- `Accounts.UserNotifier` takes its sender from the `:mail_from` setting instead of `contact@example.com`.
- Reminder form's "days before" input takes its `max` from `Reminder.max_days_before/0` instead of a hard-coded 90.
- `PaymentMethod.label/1` now renders the card as `Name **1234 (CUR)` (no space after the asterisks).
- `SubscriptionHTML.money/2` delegates to `Subtrack.Money.format/2`.
- `PaymentMethodController` and the `payment_method_html` templates (`index`, `new`, `edit`, `show`) are reformatted with `mix format`, with no behaviour change.
- Subscription form, list and detail page show billing cycles as labels (`Monthly`) from `BillingCycles`, and `Subscription.billing_cycle` takes its values from `BillingCycles.all/0`.
- Reminder form references `Subtrack.Subscriptions.Reminder` by its full module name.
- `User.contact_changeset/2` strips spaces, dashes, dots and brackets from the phone number before validating it, validates the timezone with `Subtrack.Timezones.valid?/1`, and clears `phone_confirmed_at` whenever the phone number changes.
- `users.phone_number` is now unique only among verified numbers (partial index `users_verified_phone_number_index`); verifying a number removes the verification from any other account holding it, and `contact_changeset/2` no longer carries the unique constraint.
- `Dispatcher.deliver/4` sends the `sms` channel through `Subtrack.SMS` instead of logging it, and returns `{:permanent, :no_phone_number}` or `{:permanent, :phone_not_verified}` when the user has no verified number.
- Contact settings page shows whether the number is verified and links to `/settings/phone/verify` when it is not.
- `ReminderEmail.when_text/1` is public so SMS reminders reuse the same wording.
