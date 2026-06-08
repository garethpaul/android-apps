# Changes

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
