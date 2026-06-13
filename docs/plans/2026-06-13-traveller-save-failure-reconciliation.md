# Traveller Save Failure Reconciliation

Status: Completed

## Context

Traveller updates its list optimistically when a task is created or marked
complete, then calls Parse `saveEventually()` without a callback. The vendored
Parse 1.5.0 jar supports `saveEventually(SaveCallback)`, but permanent save
failures are currently invisible and can leave phantom or incorrectly removed
tasks in the active adapter.

## Requirements

- **R1:** Attach a `SaveCallback` to both task creation and task-toggle saves.
- **R2:** On a creation failure, remove the unsaved optimistic task from the
  current adapter and show a localized generic message.
- **R3:** On a toggle failure, restore the previous completion state and adapter
  membership before showing a localized generic message.
- **R4:** Apply rollback UI work only while the activity is started and the
  adapter is available, then start a generation-guarded refresh.
- **R5:** Preserve task normalization, Parse credentials, query lifecycle,
  successful optimistic behavior, and legacy build compatibility.
- **R6:** Extend SDK-free contracts, documentation, and completed verification.

## Implementation Units

### U1: Reconcile Create Failures

**File:** `traveller-android-app/traveller/src/main/java/com/requestlabs/traveller/MainActivity.java`

Use the vendored callback overload. Remove the captured new task only when the
save reports an error and the visible activity can safely update its adapter.

### U2: Reconcile Toggle Failures

**File:** `traveller-android-app/traveller/src/main/java/com/requestlabs/traveller/MainActivity.java`

Capture the prior completion value. On error, restore the model and its list
membership, notify the adapter, and run the existing guarded refresh path.

### U3: Enforce And Document

**Files:** `scripts/check-baseline.sh`, resources, README, SECURITY, CHANGES,
this plan

Require both callback paths, lifecycle guards, rollback ordering, localized
failure text, refresh, and completed evidence.

## Test Scenarios

- Removing either `SaveCallback` fails the SDK-free checker.
- Removing creation rollback or toggle-state restoration fails the checker.
- Showing a toast or mutating the adapter before lifecycle guards fails the
  checker.
- Removing the post-rollback refresh or localized string fails the checker.
- Existing query lifecycle, task-input, row, workflow, and build contracts stay
  green.

## Scope Boundaries

- Do not change Parse versions, endpoint configuration, credentials, Gradle,
  Android plugin, SDK levels, request policy, or successful optimistic UI flow.
- Do not claim emulator, device, or live Parse backend validation without those
  environments.

## Verification

- The SDK-free checker failed before implementation because neither Parse save
  path attached a callback and the plan had no completed evidence.
- Eleven hostile mutations were rejected: removing either callback call,
  removing creation rollback, removing toggle restoration, removing completed
  task removal, delaying the lifecycle guard, removing a reconciliation refresh,
  bypassing or removing the localized resource, removing security guidance, and
  removing this canonical plan.
- SDK-backed `make check` passed with Amazon Corretto 8 and
  `/home/gjones/android-sdk`: debug and release Java compilation succeeded,
  Android lint reported zero issues, and the debug APK assembled.
- External-directory `make check`, shell syntax checks, workflow YAML parsing,
  secret-pattern scanning, and `git diff --check` passed.
- Emulator, physical-device, and live Parse backend behavior remain operational
  validation boundaries.
