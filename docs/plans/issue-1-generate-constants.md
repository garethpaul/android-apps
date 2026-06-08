# Issue 1: Generate Traveller Constants

## Context

GitHub issue: `garethpaul/android-apps#1`

The Traveller Android app imports `Constants`, but clean checkouts depend on a local credentials file. Without a generated placeholder, the project can fail before developers have a chance to configure real Parse values.

## Plan

1. Generate `Constants.java` from the checked-in `Constants.java.example` template when the local file is missing.
2. Hook generation into Gradle `preBuild` without changing the legacy Android toolchain.
3. Document the generated placeholder and verification commands in the README.
4. Extend the baseline script so it checks the generation hook and template reference.

## Verification

- Run `bash scripts/check-baseline.sh`.
- Run `git diff --check`.
