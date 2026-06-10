# Traveller In-Place Task Updates

Status: Completed

## Context

Traveller called `finish()` and immediately restarted `MainActivity` after
every task creation and toggle. Parse persistence was only queued with
`saveEventually`, so the restart added visible churn and could leave background
query callbacks associated with the activity being torn down.

## Changes

- Add newly queued tasks to the current adapter after creation.
- Remove newly completed tasks from the incomplete-task list in place.
- Refresh the adapter when a task is toggled back to incomplete.
- Prohibit activity finish/restart calls in the task mutation paths through the
  SDK-free baseline.

## Verification

- `make check`
- Static mutations for a reintroduced activity restart and missing adapter
  updates
- `git diff --check`

The Android SDK is unavailable on the current host, so a compatible Android
toolchain remains required before claiming a Gradle build or runtime test.
