---
title: Traveller Backup Policy
type: security
status: completed
date: 2026-06-09
---

# Traveller Backup Policy

## Problem Frame

Traveller is a legacy Parse-backed Android app. Its manifest allowed Android
backup, which can include app-local state on user devices by default. That is a
poor baseline for an app whose local configuration and cache are tied to Parse
account data.

## Scope Boundaries

- Keep the legacy Android Gradle, Parse, and app structure unchanged.
- Do not add a backup rules XML file or modern Android backup migration in this
  pass.
- Keep verification SDK-free because this host may not have a compatible
  Android toolchain for the old project.

## Implementation Units

### U1: Disable Manifest Backup

Files:

- Modify `traveller-android-app/traveller/src/main/AndroidManifest.xml`

Approach:

- Set `android:allowBackup` to `false` on the application.
- Leave permissions, activity wiring, and Parse initialization unchanged.

### U2: Add SDK-Free Contract Coverage

Files:

- Modify `scripts/check-baseline.sh`

Approach:

- Require `android:allowBackup="false"` in the Traveller manifest.
- Reject `android:allowBackup="true"` so future edits cannot restore the old
  backup policy silently.

### U3: Document The Privacy Baseline

Files:

- Modify `README.md`
- Modify `VISION.md`
- Modify `CHANGES.md`

Approach:

- Record the backup policy with the existing Parse credential and task input
  guardrails.
- Keep future backup-rules modernization separate from this manifest baseline.

## Verification

- `make check`
- `scripts/check-baseline.sh`
- `git diff --check`
