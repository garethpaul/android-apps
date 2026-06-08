---
title: Traveller Constants Helper
status: completed
date: 2026-06-08
origin: user-requested continuous engineering quality loop
execution: code
---

# Traveller Constants Helper

## Problem Frame

The Traveller app imports `Constants`, but only `Constants.java.example` is
tracked. Real Parse credentials must stay out of git, yet maintainers still need
a documented way to create the ignored local constants file before running the
legacy Android project.

## Scope Boundaries

- Keep real Parse credentials untracked.
- Do not change the Parse SDK, Gradle stack, or Android app behavior.
- Keep verification SDK-free unless a maintainer chooses to run nested Gradle.

## Implementation Units

### U1: Baseline Contract

Files:

- Modify `scripts/check-baseline.sh`

Approach:

- Require an executable constants preparation helper.
- Require `Constants.java` to stay ignored.
- Require README to document the helper and nested Gradle commands.

### U2: Constants Helper And Docs

Files:

- Add `scripts/prepare-traveller-constants.sh`
- Modify `README.md`
- Modify `CHANGES.md`

Approach:

- Copy `Constants.java.example` to the ignored `Constants.java` path only when
  the local file is missing.
- Document that local developers must replace placeholder values outside git.

## Verification

- `scripts/check-baseline.sh`
- `git diff --check`
