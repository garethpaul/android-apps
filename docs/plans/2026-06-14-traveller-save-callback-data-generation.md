# Keep Traveller Save Failures Per-Task Owned

Status: Completed

## Context

Traveller rejects save callbacks from stopped lifecycles and older saves of the
same `Item` identity. A global data-generation guard was considered for save
failure callbacks, but that ownership boundary is too broad: a later unrelated
task mutation can advance `mDataGeneration` and suppress rollback for an earlier
task whose save still failed. The corrected contract keeps query staleness owned
by `mDataGeneration`; same-task supersession is owned by per-task save
generations.

## Scope

- Do not capture global data generations in new-task or completion save
  callbacks.
- Reconcile a save failure when its lifecycle and task-save generation remain
  current.
- Preserve success handling, Parse persistence, optimistic UI behavior,
  query-generation ownership, and localized generic errors.
- Add mutation-sensitive portable contracts, completed plan evidence, and
  maintenance documentation.

## Implementation Units

### U1. Guard save-failure reconciliation by task ownership

**Files:**

- `traveller-android-app/traveller/src/main/java/com/requestlabs/traveller/MainActivity.java`

After confirming the callback owns the latest save for that task and belongs to
the current visible lifecycle, reconcile the failed save even if unrelated task
mutations happened later.

### U2. Protect the ownership contract

**Files:**

- `scripts/check-baseline.sh`
- `docs/plans/2026-06-14-traveller-save-callback-data-generation.md`

Reject global data-generation guards inside save callbacks while preserving the
query-generation guard for Parse result callbacks.

### U3. Document callback ownership

**Files:**

- `README.md`
- `SECURITY.md`
- `VISION.md`
- `CHANGES.md`

Describe independent optimistic save failures and per-task callback ownership.

## Verification

Completed on 2026-06-14 and corrected on 2026-06-19:

- Root and external-working-directory `make check` both passed the shell syntax
  and portable Traveller baseline checks; the legacy Gradle build was
  truthfully skipped because no Android SDK was configured.
- Focused mutations were rejected when they removed lifecycle or per-task save
  ownership, reintroduced global data-generation save guards, removed
  documentation contracts, or reopened this plan.

## Risks

- An unrelated later optimistic mutation no longer suppresses a failed save for
  another task. A same-task older callback is still suppressed by per-task save
  generations.
- This does not cancel Parse's queued persistence or replace the legacy SDK.
