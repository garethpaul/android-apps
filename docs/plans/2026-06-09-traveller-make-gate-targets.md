---
title: Traveller Make Gate Targets
type: tooling
status: completed
date: 2026-06-09
---

# Traveller Make Gate Targets

## Problem Frame

The repository had `make check` and `make verify`, but it did not expose the
standard lint, test, and build gate names from the root Makefile. That made the
required pre-push order less explicit for this legacy Android checkout.

## Scope Boundaries

- Preserve the existing SDK-free Traveller baseline script.
- Do not migrate Gradle, Android Gradle Plugin, build-tools, or dependencies.
- Do not require local Parse credentials for SDK-free checks.
- Attempt the legacy Android build only when SDK configuration and local
  constants are present.

## Implementation Units

### U1: Add Root Gate Targets

Files:

- Modify `Makefile`

Approach:

- Add `make lint` for shell syntax checks plus the SDK-free baseline.
- Add `make test` as the SDK-free Traveller contract suite.
- Add `make build` to run the nested Gradle debug build when configured and
  report a clear skip otherwise.
- Keep `make check` and `make verify` as aggregate wrappers.

### U2: Protect The Contract

Files:

- Modify `scripts/check-baseline.sh`

Approach:

- Assert that the root Makefile exposes `lint`, `test`, and `build`.
- Assert that `verify` runs the gates in the expected order.
- Assert that README maintenance notes document the gate names.

### U3: Document The Workflow

Files:

- Modify `README.md`
- Modify `VISION.md`
- Modify `CHANGES.md`

Approach:

- Record the root-level gate commands and the guarded legacy build behavior.

## Verification

- `make lint`
- `make test`
- `make build`
- `make check`
- `git diff --check`
