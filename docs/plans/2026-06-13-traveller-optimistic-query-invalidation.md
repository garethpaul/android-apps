# Traveller Optimistic Query Invalidation

Status: Completed

## Context

`onStart` launches a cached/network Parse query and guards its callback with
`mDataGeneration`. Creating or completing a task updates the adapter
optimistically but does not invalidate that in-flight query. A stale callback
can therefore clear the adapter after the local mutation, hiding a new task or
reintroducing a task that the user just completed.

## Requirements

- Invalidate the active query generation before an optimistic task creation is
  added to the adapter.
- Invalidate the active query generation before an optimistic completion
  toggle changes the model or adapter.
- Preserve one generation capture per `updateData`, lifecycle invalidation on
  stop, stale callback guards, save callbacks, failure rollback, and refreshes.
- Do not start an extra query for successful optimistic mutations.
- Add mutation-sensitive static ordering contracts and truthful verification.

## Implementation Units

### U1: Invalidate Before Local Mutations

**File:** `traveller-android-app/traveller/src/main/java/com/requestlabs/traveller/MainActivity.java`

Increment the existing generation counter after input/item validation and
immediately before each optimistic create or toggle mutation. Keep save queuing
and failure reconciliation unchanged.

### U2: Enforce Mutation Ordering

**File:** `scripts/check-baseline.sh`

Require exactly four intentional generation increments: create, toggle,
refresh capture, and stop invalidation. Prove create/toggle invalidation precedes
adapter/model mutation and save queuing, while callback application remains
guarded by generation equality.

### U3: Document And Verify

**Files:** `README.md`, `SECURITY.md`, `VISION.md`, `CHANGES.md`, this plan

Document stale-query invalidation for optimistic changes. Run focused hostile
mutations, SDK-free and configured Android gates, an external-directory check,
diff/artifact/secret scans, and exact-head hosted verification.

## Scope Boundaries

- Do not change Parse dependencies, cache policy, query filters, persistence,
  save semantics, UI layout, task schema, or credentials.
- Do not add retries, queues, per-item versioning, or conflict resolution.
- Do not claim live Parse, emulator, or physical-device behavior without
  execution evidence.

## Verification Plan

- Reject hostile mutations removing or moving create/toggle invalidation,
  changing increment counts, weakening callback guards, or rolling back docs
  and completed-plan evidence.
- Run `make check` locally and from an isolated external directory.
- Run `git diff --check`, generated-artifact inspection, and credential-shaped
  added-line scans before committing implementation paths.
- Record hosted evidence only after querying the exact pushed head.

## Verification

- The focused checker initially reached only the expected incomplete-plan
  assertion after implementation and documentation were added.
- Eight focused hostile mutations were rejected: removed and reordered create
  invalidation, removed and reordered toggle invalidation, weakened callback
  generation guard, extra generation increment, security-guidance rollback,
  and completed-plan rollback.
- Local and isolated external-directory `make check` passed shell syntax and
  every SDK-free contract; both truthfully skipped Gradle because no Android
  SDK is configured in these worktrees.
- The isolated copy used its own temporary Git index because the checker
  intentionally inspects tracked files.
- `git diff --check`, generated-artifact inspection, and credential-shaped
  added-line scans passed. Hosted exact-head evidence remains pending push.
