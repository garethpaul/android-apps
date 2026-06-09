# Traveller Parse Query Failures

## Status: Completed

## Context

`MainActivity.updateData()` refreshed the adapter when Parse returned tasks, but
it ignored `ParseException` failures. A failed query could therefore leave stale
or empty UI state without any visible signal to the user or maintainer.

## Objectives

- Preserve the existing cache-then-network Parse query behavior.
- Only update the task adapter when Parse returns a successful task list.
- Show a localized, non-secret error message when task loading fails.
- Keep the behavior covered by the SDK-free baseline checker.

## Work Completed

- Updated `MainActivity.updateData()` to check `error == null && tasks != null`
  before refreshing the adapter.
- Added a localized `load_items_error` string and displayed it with `Toast`.
- Extended `scripts/check-baseline.sh` to reject silent Parse query failures and
  require the localized error string.
- Updated README, VISION, and CHANGES notes for the visible error contract.

## Verification

- `scripts/check-baseline.sh`
- `make check`
- `git diff --check`

Gradle verification still requires a compatible Android SDK from inside
`traveller-android-app/`.
