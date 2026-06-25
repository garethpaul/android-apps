# Traveller Query Lifecycle Guard

Status: Completed

## Context

`MainActivity.updateData()` starts a Parse `CACHE_THEN_NETWORK` query whose
callback closes over the activity and adapter. The callback currently mutates
the list or shows a toast regardless of whether the activity has stopped, and
an older callback can overwrite a newer refresh after the activity restarts.
The legacy Parse API does not expose a reliable cancellation handle in this
code path, so result application needs an activity-local generation contract.

## Prioritized Scope

1. Refresh Traveller items when the activity enters the started state.
2. Track whether the activity is active and assign each refresh a monotonically
   increasing generation.
3. Invalidate the current generation when the activity stops.
4. Ignore callbacks when the activity is stopped, the adapter is unavailable,
   or a newer refresh superseded the callback.
5. Preserve `CACHE_THEN_NETWORK`, incomplete-item filtering, in-place task
   updates, error messaging for the active refresh, and all existing guards.
6. Extend the SDK-free baseline and project documentation with the lifecycle
   contract.

## Implementation Units

### Activity And Query State

Files: `traveller-android-app/traveller/src/main/java/com/requestlabs/traveller/MainActivity.java`

- Add active-state and query-generation fields.
- Move the initial refresh from `onCreate` to `onStart` so every visible
  activity instance requests current data.
- Mark the activity inactive and invalidate outstanding generations in
  `onStop` before calling the superclass.
- Capture the current generation in `updateData` and return early from stale
  callbacks before touching the adapter or showing a toast.

### Static Regression Contracts

Files: `Makefile`, `scripts/check-baseline.sh`

- Require the active-state field, generation field, start/stop transitions,
  captured generation, and callback guard ordering.
- Require the SDK-backed build target to run Android lint before debug APK
  assembly.
- Require this completed plan and its `make check` verification note.

### Documentation

Files: `README.md`, `SECURITY.md`, `VISION.md`, `CHANGES.md`

- Document visible-lifecycle refreshes and stale callback suppression.
- Record the Android SDK/runtime verification limitation for the legacy build.

## Risks

- Moving refresh initiation to `onStart` increases queries when repeatedly
  entering the activity. This is intentional so ignored background results are
  replaced with a current visible refresh.
- Generation comparison must occur before adapter mutation and toast creation;
  otherwise the lifecycle guard would not protect the UI boundary.
- The static checker cannot prove Android or Parse runtime behavior. A legacy
  SDK build and device/emulator run remain required before claiming platform
  execution coverage.

## Verification

- `make check` passed with Amazon Corretto 8, the configured Android SDK, and
  ignored placeholder `Constants.java` generated from the checked-in example.
- Gradle compiled debug and release Java sources, reported zero Android lint
  issues, and assembled the debug APK.
- The SDK-free baseline passed and rejected mutations that removed started
  state, generation capture, stop-time invalidation, callback ordering, the
  combined Gradle lint/build command, or completed-plan evidence.
- `git diff --check` passed.
