# Traveller Per-Task Save Generation

Status: Completed

## Context

Traveller rejects save callbacks from an older visible activity lifecycle, but
multiple saves of the same `Item` within one lifecycle share that generation.
A late failure from an earlier save can therefore roll back a newer optimistic
state or remove a task that has since been saved again.

## Scope

- Track a monotonically increasing save generation per `Item` identity.
- Accept completion only for the latest save of that item and clear accepted
  generations on callback or activity stop.
- Preserve independent save callbacks for different tasks, optimistic adapter
  behavior, lifecycle gating, failure toasts, and refresh reconciliation.
- Add mutation-sensitive portable contracts for generation assignment,
  callback ordering, stop cleanup, documentation, and completed plan evidence.

## Implementation Units

### 1. Own save generations per task

Files:

- `traveller-android-app/traveller/src/main/java/com/requestlabs/traveller/MainActivity.java`

Use identity-keyed generations for both new-task and completion saves. Reject a
callback before success or failure handling when a newer save owns the task.

### 2. Protect the race boundary

Files:

- `scripts/check-baseline.sh`
- `docs/plans/2026-06-14-traveller-per-task-save-generation.md`

Require per-task storage, generation capture before each save, callback checks
before error handling, lifecycle cleanup, and completed verification evidence.

### 3. Document the behavior

Files:

- `README.md`
- `SECURITY.md`
- `VISION.md`
- `CHANGES.md`

Describe same-item stale save callback suppression separately from activity
lifecycle suppression.

## Verification

Completed on 2026-06-14:

- The SDK-free checker recognized per-task identity storage, both generation
  captures and callback guards, pre-error ordering, stop cleanup, and project
  documentation, failing only while this plan was intentionally planned.
- Configured `make check` passed shell syntax and the SDK-free baseline twice;
  the Android build was truthfully skipped because the untracked local
  `Constants.java` credential/configuration file is absent.
- Seven isolated mutations were rejected when they replaced identity storage,
  removed generation capture or callback ownership, moved the guard after
  success handling, removed stop cleanup or security wording, or changed this
  plan back to `Status: Planned`.

## Risks

- Save generations are activity-local and intentionally reset when the activity
  stops; callbacks from the stopped lifecycle remain ignored.
- Parse's eventual-save queue remains the persistence mechanism; this change
  only prevents stale callbacks from reconciling newer UI state.
