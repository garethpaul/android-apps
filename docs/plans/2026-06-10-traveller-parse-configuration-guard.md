# Traveller Parse Configuration Guard

Status: Completed

## Goal

Fail clearly before Parse SDK initialization when Traveller is started with
blank values or the checked-in local configuration placeholders.

## Requirements

- Validate both local Parse values before calling `Parse.initialize`.
- Call `Application.onCreate()` before Traveller-specific startup work.
- Reject null, blank, and unchanged placeholder values.
- Keep diagnostics free of configured credential values.
- Preserve ignored local `Constants.java` setup and the legacy Parse SDK API.
- Enforce the behavior with the SDK-free baseline checker.
- Make root verification work outside the repository directory.
- Pin hosted verification and cancel superseded runs.

## Implementation

- Add explicit application-id and client-key placeholder constants to `App`.
- Restore the superclass lifecycle call before configuration validation.
- Add a small shared value validator and fail with `IllegalStateException`
  before Parse initialization when configuration is incomplete.
- Extend `scripts/check-baseline.sh` with configuration, rooted `Makefile`, and
  CI runner/concurrency contracts.
- Resolve Make paths from the Makefile location and pin GitHub Actions to
  Ubuntu 24.04.

## Verification

- `make check`
- `make -f /absolute/path/to/Makefile check` from outside the repository
- Parse-configuration and automation mutation checks
- shell syntax checks
- `git diff --check`

The Android SDK is not available on this host, so a compatible legacy SDK must
still compile and run the app before claiming device-level behavior.
