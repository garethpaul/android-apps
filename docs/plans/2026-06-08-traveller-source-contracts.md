---
title: Traveller Source Contracts
status: completed
date: 2026-06-08
origin: user-requested continuous engineering quality loop
execution: code
---

# Traveller Source Contracts

## Problem Frame

The legacy Traveller Android project now has SDK-free reproducibility checks,
but the source still had two small maintainability issues that static checks can
protect: row views were inflated without parent layout params, and `Item` was
registered as a Parse subclass twice during activity startup.

## Scope Boundaries

- Preserve the Traveller UI and Parse-backed behavior.
- Do not migrate Android Gradle Plugin, Gradle, Parse, or support libraries.
- Do not add Android instrumentation tests without a compatible SDK setup.

## Implementation Units

### U1: Source Cleanup

Files:

- `traveller-android-app/traveller/src/main/java/com/requestlabs/traveller/ItemAdapter.java`
- `traveller-android-app/traveller/src/main/java/com/requestlabs/traveller/MainActivity.java`

Approach:

- Inflate row layouts with `parent` and `attachToRoot=false`.
- Register the `Item` Parse subclass exactly once in `onCreate`.

### U2: SDK-Free Contracts

Files:

- `scripts/check-baseline.sh`
- `README.md`
- `CHANGES.md`

Approach:

- Extend the baseline script to prevent null-parent row inflation.
- Extend the baseline script to require exactly one `Item` subclass registration.
- Document that the SDK-free baseline covers these source-level contracts.

## Verification

- `make check`
- `scripts/check-baseline.sh`
- `git diff --check`
