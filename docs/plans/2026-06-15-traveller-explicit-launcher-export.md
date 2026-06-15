---
title: Traveller Explicit Launcher Export Boundary
type: security
status: planned
date: 2026-06-15
---

# Traveller Explicit Launcher Export Boundary

## Problem Frame

Traveller's launcher activity has a `MAIN`/`LAUNCHER` intent filter but does
not declare `android:exported`. Legacy Android versions infer that the activity
is exported because of the filter. This leaves the externally reachable
component boundary implicit to maintainers and security tooling, and it blocks
a future target-SDK upgrade because Android 12 requires components with intent
filters to declare their exported state explicitly.

## Priorities

1. P0: Preserve the launcher entry point while making its external reachability
   explicit in the maintained manifest.
2. P1: Add a portable, mutation-sensitive contract that couples the exported
   declaration to the `MAIN` and `LAUNCHER` intent filter.
3. P1: Keep contributor, security, vision, readme, and change guidance aligned
   with the manifest boundary and verified completion state.

## Requirements

- Declare `MainActivity` as explicitly exported because it owns the app's
  launcher intent filter.
- Preserve the existing application class, launcher action/category, icon,
  label, permissions, backup policy, and activity implementation.
- Require exactly one launcher activity with `android:exported="true"` in the
  portable baseline checker.
- Reject a missing, false, duplicated, or unrelated exported declaration.
- Document that only the launcher activity is intentionally externally
  reachable; Parse credentials and backend behavior remain unchanged.

## Implementation Units

### 1. Declare launcher reachability

**File:**
`traveller-android-app/traveller/src/main/AndroidManifest.xml`

Add the explicit exported attribute to `MainActivity` without changing its
intent filter or any other manifest behavior.

### 2. Enforce the manifest contract

**File:** `scripts/check-baseline.sh`

Parse the activity block containing the `MAIN` and `LAUNCHER` filter and
require the expected activity name plus one true exported declaration. Keep
the check independent of the caller's working directory.

### 3. Synchronize maintenance guidance

**Files:** `AGENTS.md`, `README.md`, `SECURITY.md`, `VISION.md`, `CHANGES.md`,
and this plan.

Record the intentional launcher export boundary, completed validation, and
remaining legacy-platform limitations.

## Verification

- Run `sh -n scripts/check-baseline.sh` and the focused portable checker.
- Run `make check` from the repository root and through the absolute Makefile
  path from an external directory.
- Reject isolated mutations for a missing declaration, `false`, a declaration
  on the application rather than launcher activity, removed intent-filter
  coupling, missing guidance, and incomplete plan status.
- Audit generated Android artifacts, the exact diff, whitespace, conflict
  markers, file modes, and changed lines for credential material.
- Record unavailable Android SDK, emulator, physical-device, and live Parse
  validation without claiming those scenarios ran.

## Risks And Mitigations

- **Launcher regression:** retain the exact `MAIN` action and `LAUNCHER`
  category and require them alongside the exported declaration.
- **Over-broad exposure:** declare only the existing launcher activity; do not
  export the application or add services, receivers, providers, or filters.
- **Legacy toolchain:** use the long-supported manifest attribute without
  upgrading Gradle, Android plugin, SDK levels, or dependencies in this change.
- **Stacked delivery:** base the pull request on the Parse subclass bootstrap
  branch and preserve base-first merge ordering.

## Out Of Scope

- Upgrading target SDK, compile SDK, Gradle, Android plugin, appcompat, or the
  vendored Parse SDK.
- Adding deep links, services, receivers, providers, or additional activities.
- Changing Parse credentials, endpoints, queries, task persistence, or UI
  behavior.
