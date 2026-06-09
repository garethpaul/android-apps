# Traveller Task Input Null Guard

## Status: Completed

## Context

Traveller task creation already trims task descriptions before validation, but
the helper assumed the `EditText` and its text value were always available. A
stale or malformed legacy layout could crash before the existing empty-task
guard had a chance to skip creation.

## Objectives

- Preserve the normalized task description helper.
- Treat missing task input views or text values as empty task descriptions.
- Preserve the existing behavior that empty descriptions are not saved.
- Keep verification available without an Android SDK.

## Work Completed

- Added a null guard to `normalizedTaskDescription()`.
- Returned an empty string when the input view or text is unavailable.
- Extended `scripts/check-baseline.sh` to cover the null guard and plan.
- Updated README, VISION, and CHANGES.

## Verification

- `scripts/check-baseline.sh`
- `sh -n scripts/check-baseline.sh`
- `sh -n scripts/prepare-traveller-constants.sh`
- `make lint`
- `make test`
- `make build`
- `make check`
- `git diff --check`

On this workspace, `make build` and `make check` reported
`Android SDK not configured; skipping Traveller Gradle build`.

## Follow-Up Candidates

- Add instrumentation coverage for malformed Traveller layouts.
- Replace activity restart refreshes with a direct adapter update once Android
  modernization is scoped.
