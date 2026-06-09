---
title: Traveller Task Input Normalization
type: reliability
status: completed
date: 2026-06-09
---

# Traveller Task Input Normalization

## Problem Frame

Traveller's `createTask` flow checks `mTaskInput.getText().length()` before
saving, then stores `mTaskInput.getText().toString()` directly. Whitespace-only
inputs can therefore create empty-looking Parse `Item` records, and leading or
trailing spaces become persisted data.

## Scope Boundaries

- Preserve the existing Parse `Item` fields and `saveEventually()` behavior.
- Do not change list refresh, activity restart, adapter behavior, or backend
  configuration in this pass.
- Keep verification SDK-free because the local Android SDK may be unavailable.

## Implementation Units

### U1: Normalize Task Input Before Save

Files:

- Modify `traveller-android-app/traveller/src/main/java/com/requestlabs/traveller/MainActivity.java`

Approach:

- Extract a small `normalizedTaskDescription()` helper.
- Trim the input before validation.
- Save the normalized description instead of the raw `EditText` text.

### U2: Extend Static Baseline Contracts

Files:

- Modify `scripts/check-baseline.sh`

Approach:

- Assert that task input is trimmed before validation and persistence.
- Assert that the old raw-length check does not return.

### U3: Document The Contract

Files:

- Modify `README.md`
- Modify `CHANGES.md`
- Modify `VISION.md`

Approach:

- Record the input-normalization behavior and link this plan from maintenance
  notes.

## Verification

- `make check`
- `scripts/check-baseline.sh`
- `git diff --check`

Nested Gradle verification remains dependent on a compatible Android SDK.
