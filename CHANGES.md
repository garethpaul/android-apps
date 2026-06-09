# Changes

## 2026-06-09

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
