# Traveller Save Callback Lifecycle

Status: Planned

## Context

Traveller rejects stopped or superseded Parse query callbacks with
`mStarted` and `mDataGeneration`, but task-creation and completion
`saveEventually` callbacks only inspect the current `mStarted` value. A save
failure started before `onStop` can therefore arrive after a later `onStart`
and reconcile against the newly resumed adapter because `mStarted` is true
again.

## Requirements

- Track a visible-lifecycle generation independently from query and optimistic
  data generations.
- Advance the lifecycle generation on both `onStart` and `onStop`.
- Capture the active lifecycle generation before each of the two
  `saveEventually` operations.
- Ignore save callbacks unless the activity is still started, the captured
  lifecycle generation is current, and the adapter exists.
- Preserve same-lifecycle save failure rollback, user feedback, backend
  reconciliation, optimistic adapter updates, and query invalidation.
- Add mutation-sensitive static coverage, documentation, and truthful
  verification evidence.

## Implementation Units

### U1: Guard Save Callbacks By Lifecycle

**File:** `traveller-android-app/traveller/src/main/java/com/requestlabs/traveller/MainActivity.java`

Add a dedicated lifecycle generation, capture it in both save helpers, and
include equality in the existing callback guard before adapter, toast, or
refresh work.

### U2: Extend Portable Contracts

**File:** `scripts/check-baseline.sh`

Require the lifecycle field, start/stop increments, two save captures, two
callback guards, guard ordering, and the completed plan and guidance markers.

### U3: Document And Verify

**Files:** `AGENTS.md`, `README.md`, `SECURITY.md`, `VISION.md`, `CHANGES.md`, this plan

Document stale save-callback rejection. Run local and isolated `make check`,
hostile mutations, available Android verification, and final diff, artifact,
credential, and exact-head hosted checks.

## Scope Boundaries

- Do not cancel Parse offline saves or change `saveEventually` semantics.
- Do not use `mDataGeneration` to invalidate unrelated same-lifecycle saves.
- Do not change task ordering, row rendering, input normalization, Parse
  configuration, or query cache policy.
- Do not claim emulator, physical-device, or live Parse backend validation.

## Verification Plan

- Run `make check` locally and from an isolated external directory.
- Prove hostile mutations for missing start/stop increments, missing save
  captures, missing callback equality, guard reordering, documentation drift,
  and incomplete-plan status fail.
- Run the Android lint, unit-test, Java compile, and debug-assembly path when a
  compatible Java 8 and Android SDK are available; otherwise record the skip.
- Run `git diff --check`, generated-artifact inspection, and
  credential-shaped added-line scans.
- Record hosted evidence only after querying the exact pushed head.

## Verification

- Pending implementation.
