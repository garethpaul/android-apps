# Traveller Item Toggle Guards

## Status: Completed

## Context

Traveller marks Parse-backed items complete from `onItemClick`. The handler
assumed the adapter, selected `Item`, row `View`, and row description
`TextView` were all present and correctly typed. Stale list state or layout
drift could crash the legacy activity before it saves the toggle.

## Objectives

- Preserve item completion toggling for valid rows.
- Ignore toggle events when the adapter is unavailable.
- Ignore toggle events when no selected task exists.
- Ignore toggle events when the row view is unavailable.
- Ignore toggle events when the row description view is unavailable or not a
  `TextView`.
- Keep the SDK-free baseline check covering the guards.

## Work Completed

- Added adapter, task, row-view, and row text-view guards to `onItemClick`.
- Guarded malformed row description views before casting them to `TextView`.
- Left the existing Parse save and activity refresh behavior unchanged for
  valid rows.
- Extended `scripts/check-baseline.sh`.
- Updated README, VISION, and CHANGES.

## Verification

- `scripts/check-baseline.sh`
- `make check`
- `git diff --check`

On this workspace, `make check` reported `Android SDK not configured; skipping
Traveller Gradle build`.

## Follow-Up Candidates

- Add Android/JVM tests for item toggles after the legacy Gradle stack is
  modernized.
- Add an explicit empty-state UI when Parse returns no tasks.
