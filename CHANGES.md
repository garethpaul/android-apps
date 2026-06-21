# Changes

## 2026-06-21

- Made the repository build gate fail closed when Android SDK tooling is absent
  instead of reporting a successful skip.
- Allowed SDK-configured clean builds to reach Gradle so `preBuild` can generate
  the ignored local `Constants.java` before lint and debug assembly.
- Added behavioral build-gate and constants-generation regressions and
  provisioned Android API 19 plus build-tools 24.0.3 in hosted verification.

## 2026-06-17

- Traveller removes ASCII and Unicode boundary whitespace before rejecting empty task descriptions.
- Added executable regressions for Unicode-space-only input, Unicode boundary
  trimming, preserved interior spacing, and legacy control-character trimming.

## 2026-06-16

- Extracted Traveller task-description behavior into a package-local pure Java
  normalizer used by `MainActivity`.
- Added a dependency-free JVM test for null, empty, whitespace-only, ASCII, and
  Unicode descriptions, with temporary compiler output cleaned on every exit.
- Pinned hosted Java setup, disabled persisted checkout credentials, and made
  feature-branch pushes run the canonical `make check` gate.

## 2026-06-15

- Added an explicit launcher export boundary for Traveller's sole
  `MAIN`/`LAUNCHER` activity and a structural manifest contract that rejects
  implicit, false, duplicated, or unrelated export declarations.
- Moved `Item` to application-owned Parse subclass registration before SDK
  initialization, preventing activity recreation from repeating global setup.
- Added mutation-sensitive ownership and initialization-order contracts.

## 2026-06-13

- Added callbacks for optimistic task save failures so unsaved new rows are
  removed and failed completion toggles restore their prior state.
- Added lifecycle-gated localized errors, guarded refresh reconciliation, and
  SDK-free regression contracts for both save paths.
- Invalidated stale Parse query callbacks before optimistic creates and toggles
  so older query snapshots cannot overwrite the current adapter action.
- Added mutation-sensitive generation-order contracts and guidance.
- Rejected stale save callbacks from earlier visible lifecycles before they can
  reconcile against a newly resumed adapter.
- Added per-task save generations so late same-item callbacks cannot reconcile
  over a newer optimistic save in the same visible lifecycle.
- Corrected independent optimistic save failures so unrelated later task
  mutations no longer suppress rollback, notification, and refresh.
- Suppressed expected Parse cache-miss callbacks while `CACHE_THEN_NETWORK`
  continues to the backend, preserving toasts for actual load failures.
- Suppressed later Parse network-error toasts after a successful cached task delivery
  while preserving visible failures when a query has not delivered usable data.
- Added an exact-commit Android device and Parse backend verification matrix for
  configuration, queries, optimistic saves, concurrency, lifecycle, failures,
  and privacy-safe evidence, with every runtime row explicitly unexecuted.

## 2026-06-12

- Moved Traveller item refreshes into the visible activity lifecycle.
- Added query generations so callbacks from stopped or superseded Parse
  refreshes cannot mutate the adapter or show stale errors.
- Extended the SDK-free baseline and documentation with lifecycle ordering
  contracts.
- Strengthened the SDK-backed `make build` gate to run Android lint before
  assembling the debug APK.

## 2026-06-10

- Added a fail-fast Traveller guard that rejects blank or unchanged Parse
  placeholders before SDK initialization without logging credential values.
- Restored the superclass `Application.onCreate()` call before Traveller
  configuration and Parse startup.
- Made root verification location-independent and pinned CI to Ubuntu 24.04
  with superseded-run cancellation.
- Added pinned, read-only GitHub Actions CI that runs the root `make check`
  Traveller baseline with a bounded timeout and manual dispatch.

## 2026-06-09

- Guarded Traveller item toggles when list-click positions fall outside the
  adapter bounds.
- Added SDK-free baseline coverage for stale item-toggle positions.
- Removed tracked nested Android Studio `.idea` metadata from the Traveller
  project.
- Tightened the SDK-free baseline to reject nested `.idea/` and `.vscode/`
  metadata.
- Guarded Traveller row rendering when the backing item, task description, or
  row text view is missing or malformed.
- Added SDK-free baseline coverage for item-row rendering guards.
- Removed tracked Traveller IDE module metadata and added an SDK-free baseline
  guard for `.iml`, `.idea/`, and `.vscode/` ignore rules.
- Guarded Traveller item toggles when the adapter, selected item, row view, or
  row text view is unavailable or malformed.
- Added SDK-free baseline coverage for item-toggle null guards.
- Guarded Traveller task description normalization when the task input view or
  text value is unavailable.
- Added explicit `make lint`, `make test`, and guarded `make build` gates so
  Traveller verification can follow the repository-wide pre-push order.
- Disabled Android backup for the Traveller app and added an SDK-free manifest
  contract so local Parse state is not backed up by default.
- Made Traveller Parse query failures visible through a localized toast and
  added a baseline contract so task loading errors are not silently ignored.
- Replaced activity restarts after task creates and toggles with in-place
  adapter updates while Parse persistence remains queued.

## 2026-06-08

- Added a repository changelog and expanded the documented Traveller Android
  verification gate.
- Fixed Android lint findings by moving UI text into string resources and
  removing the unused starter layout.
- Added a narrow lint configuration for the intentionally pinned legacy Android
  dependency baseline and obsolete lint API database limitation.
- Added a local Traveller constants preparation contract so ignored Parse
  credential files can be created from the checked-in example.
- Added `make check` as the repository-standard wrapper around the SDK-free
  Traveller baseline.
- Fixed Traveller row inflation to preserve parent layout params and removed
  duplicate `Item` Parse subclass registration.
- Trimmed Traveller task input before validation and persistence so
  whitespace-only entries are not saved.
