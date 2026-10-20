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
