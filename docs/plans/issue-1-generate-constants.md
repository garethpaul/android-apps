# Generate Traveller Constants Before Build

Status: Completed

Issue: `garethpaul/android-apps#1`

Resolution: merged in aggregate PR #4 at commit `0810256` on 2026-06-25.

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

The maintained regression suite now verifies the Gradle dependency, generated
placeholder contents, non-overwrite behavior for local credentials, and the
clean-checkout build gate without requiring Android or Parse services.
