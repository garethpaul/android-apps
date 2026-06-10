# CI Baseline

Status: Completed

## Context

The portfolio remediation plan calls for lightweight CI on high-priority repos
that already have passing local checks. The Traveller project can run its
repository baseline without Android SDK credentials, while `make build` skips
the nested Gradle build when the SDK or local constants are unavailable.

## Completed Scope

- Added a GitHub Actions workflow for pushes, pull requests, and manual runs.
- Pinned checkout to an immutable revision, limited permissions to repository
  reads, and bounded the job to five minutes.
- Configured CI to run `make check`, which exercises the SDK-free Traveller
baseline in `scripts/check-baseline.sh`.
- Extended the baseline and docs so the CI gate remains visible.

The hosted job intentionally does not claim Android compilation. A dependable
build requires a separate migration from Gradle 1.10, Android Gradle Plugin
0.8.3, support library 19, Parse 1.5.0, and generated local constants.

## Verification

- `make check`
- `git diff --check`
