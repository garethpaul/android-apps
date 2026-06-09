# Traveller Editor Metadata Ignore

## Status: Completed

## Context

Traveller still tracked IntelliJ `.iml` module files. Those files are generated
IDE workspace metadata and can drift with local Android Studio or IntelliJ
configuration instead of representing Traveller source behavior.

## Objectives

- Remove tracked Traveller `.iml` files.
- Ignore IntelliJ, Android Studio, and VS Code workspace metadata.
- Extend the SDK-free baseline so editor metadata cannot return unnoticed.
- Document the guardrail in README, SECURITY, VISION, and CHANGES.

## Work Completed

- Added `.idea/`, `.vscode/`, and `*.iml` ignore rules.
- Removed tracked Traveller module files.
- Added baseline checks for editor metadata ignore rules and tracked-file
  absence.

## Verification

- `scripts/check-baseline.sh`
- `make lint`
- `make test`
- `make build`
- `make check`
- `git diff --check`
