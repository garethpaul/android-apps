# Generate Traveller Constants Before Build

Status: Completed

Issue: `garethpaul/android-apps#1`

The Traveller Android app imports `Constants`, but clean checkouts depend on a
local credentials file. Without a generated placeholder, the project can fail
before developers have a chance to configure real Parse values.

## Implementation

1. Gradle `preBuild` delegates to the repository's idempotent constants helper.
2. The helper copies `Constants.java.example` only when `Constants.java` is absent.
3. Existing local credentials are never overwritten.
4. Application startup continues to reject blank or unchanged placeholder values.

## Verification

- Run `make test` for executable generation and non-overwrite checks.
- Run `make lint` for the fail-closed source contracts.
- Run `make check` when the legacy Java and Android SDK toolchain is available.

No Java runtime, Android SDK, emulator, physical device, or live Parse scenario
was executed while recovering the closed pull request history.
