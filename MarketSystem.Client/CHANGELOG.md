# Changelog

All notable user-facing and operator-facing changes to the Flutter client
are recorded here. Versions are tagged in `pubspec.yaml` and follow
semantic-ish: bumps that require operator action (re-login, app re-install,
config migration) are called out under "Breaking" with a one-line summary
at the top of the entry.

---

## Unreleased

### Breaking — backend deploy forces a one-time re-login

The matching backend release ships two changes that invalidate every
existing refresh-token row in the database the moment it deploys:

  - K1: refresh tokens are now stored as a SHA-256 hash, not the
    plaintext value. The lookup hashes the incoming plaintext before
    comparing, so every pre-deploy row becomes unreachable.
  - S1: the backend now actively detects refresh-token rotation reuse
    and revokes the entire token family on detection.

**Operator action**: none — the migration is automatic. On the first
request after deploy each user receives a 401, the client surfaces a
"Sessiya tugadi, qayta kiring" / "Сессия истекла, войдите снова" snackbar
(localized), and routes them to /login. No data is lost. Users who keep
the app open during the deploy will see the snackbar at the next API
call (~30 seconds after their access token expires); users who launch
the app after deploy go through /splash → /login as normal.

The handling is implemented in:

  - `lib/data/services/http_service.dart` — new `sessionEndedStream`
    fires once per failed refresh.
  - `lib/core/app/main_app.dart` — global listener, snackbar + redirect.
  - `lib/core/providers/auth_provider.dart` — clears in-memory user.

### Added

  - `lib/core/validators/password_validator.dart` — unified client-side
    password policy matching the backend's StrongPasswordAttribute
    (8+ chars, ≥1 letter, ≥1 digit). Applied on add-user sheet,
    create-owner dialog, approve-request dialog, profile change-password
    sheet. `passwordMinLength` l10n string updated in uz / ru to reflect
    the new rules.
  - `test/password_validator_test.dart` — 7 cases pinning the policy.

### Changed

  - `lib/features/sales/presentation/widgets/continue_sale_cart_item.dart`:
    the per-row pencil-edit chip now hides for sales in any state other
    than Draft / Debt (was: any state other than Closed). Mirrors backend
    S2 — `SaleService.UpdateSaleItemPriceAsync` refuses Paid /
    Cancelled at the server, the client now refuses to surface the
    affordance.

---

## Earlier releases

See git history. This file starts with the deploy that ships K1 / S1 /
S2 / Y2.
