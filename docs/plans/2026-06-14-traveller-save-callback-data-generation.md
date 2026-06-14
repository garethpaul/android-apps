# Bind Traveller Save Failures to Data Generations

Status: Completed

## Context

Traveller rejects save callbacks from stopped lifecycles and older saves of the
same `Item` identity. A later Parse query or optimistic mutation can still
supersede the adapter contents while an earlier save remains current for its
old object identity. If that save fails, its callback can remove or re-add the
stale object after newer data is visible.

## Scope

- Capture the current data generation when each new-task or completion save is
  queued.
- Reconcile a save failure only when its lifecycle, task-save generation, and
  data generation all remain current.
- Preserve success handling, Parse persistence, optimistic UI behavior,
  query-generation ownership, and localized generic errors.
- Add mutation-sensitive portable contracts, completed plan evidence, and
  maintenance documentation.

## Implementation Units

### U1. Guard save-failure reconciliation

**Files:**

- `traveller-android-app/traveller/src/main/java/com/requestlabs/traveller/MainActivity.java`

Capture the initiating data generation in both save paths. After confirming the
callback owns the latest save for that task, reject failed callbacks whose data
generation was superseded before they mutate the adapter, restore completion
state, show an error, or launch another query.

### U2. Protect the ordering contract

**Files:**

- `scripts/check-baseline.sh`
- `docs/plans/2026-06-14-traveller-save-callback-data-generation.md`

Require exactly two data-generation captures and guards, with each guard after
the save-generation check and before failure reconciliation.

### U3. Document callback ownership

**Files:**

- `README.md`
- `SECURITY.md`
- `VISION.md`
- `CHANGES.md`

Describe data-generation ownership as part of optimistic save-failure safety.

## Verification

Completed on 2026-06-14:

- Root and external-working-directory `make check` both passed the shell syntax
  and portable Traveller baseline checks; the legacy Gradle build was
  truthfully skipped because no Android SDK was configured.
- Six focused mutations were rejected when they removed a capture or guard,
  moved reconciliation before the guard, removed documentation contracts, or
  reopened this plan.

## Risks

- A superseded failed save will no longer show a toast or force a refresh; the
  newer query or mutation already owns the visible state.
- This does not cancel Parse's queued persistence or replace the legacy SDK.
