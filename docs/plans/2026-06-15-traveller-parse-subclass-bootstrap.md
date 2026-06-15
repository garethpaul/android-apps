---
title: Traveller Parse Subclass Bootstrap
type: reliability
status: planned
date: 2026-06-15
---

# Traveller Parse Subclass Bootstrap

## Problem Frame

`Item` is currently registered with Parse from `MainActivity.onCreate`, after
the application has already called `Parse.initialize`. Activity recreation can
repeat this process-wide SDK registration, and its ordering conflicts with the
Parse Android guidance to register custom subclasses in the `Application`
bootstrap before SDK initialization.

Primary reference:
https://docs.parseplatform.org/android/guide/#subclassing-parseobject

## Requirements

- Register `Item.class` exactly once from `App.onCreate` before
  `Parse.initialize`.
- Remove Parse subclass registration and its unused import from
  `MainActivity`.
- Preserve Parse configuration validation, analytics tracking, query behavior,
  optimistic saves, lifecycle generations, adapter behavior, and public app
  behavior.
- Extend the portable source contract to require application-owned registration
  and its ordering before initialization.
- Document the process-wide bootstrap boundary in contributor, security,
  vision, readme, and change guidance.

## Implementation Units

### 1. Move subclass registration into application startup

**Files:**
`traveller-android-app/traveller/src/main/java/com/requestlabs/traveller/App.java`,
`traveller-android-app/traveller/src/main/java/com/requestlabs/traveller/MainActivity.java`

Import `ParseObject` in the application class, register `Item` immediately
before Parse configuration validation and initialization, and remove the
activity-scoped registration.

### 2. Enforce the process-wide ownership contract

**Files:** `scripts/check-baseline.sh`

Require exactly one registration across production Java source, require it in
`App.java`, reject it in `MainActivity.java`, and verify the registration line
precedes `Parse.initialize`.

### 3. Synchronize maintenance guidance

**Files:** `AGENTS.md`, `README.md`, `SECURITY.md`, `VISION.md`, `CHANGES.md`

Record that Parse model registration is application-owned and ordered before
SDK initialization.

## Verification

- Run POSIX shell syntax validation and the focused baseline checker.
- Run `make check` from the repository root and through the absolute Makefile
  path from an external directory.
- Reject hostile mutations that restore activity registration, duplicate the
  registration, or move registration after Parse initialization.
- Audit the exact diff, generated Android artifacts, whitespace, and changed
  lines for credential material before committing.
- Record Android SDK or emulator limitations without claiming unexecuted
  platform validation.

## Risks And Mitigations

- **Initialization ordering:** retain the existing configuration guard and place
  registration directly before it so no configured Parse call precedes model
  ownership setup.
- **Legacy SDK behavior:** keep the bundled Parse 1.5.0 API call unchanged; only
  its lifecycle owner and ordering move.
- **Stacked delivery:** base the pull request on the cache-success error
  suppression branch and preserve base-first merge ordering.

## Out Of Scope

- Upgrading the bundled Parse SDK or Android Gradle toolchain.
- Changing backend credentials, endpoints, query policies, or persistence.
- Running a live Parse backend, emulator, or physical-device scenario.
