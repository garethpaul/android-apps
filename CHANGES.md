# Changes

## 2026-06-10

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
