# Traveller Cache-Success Error Suppression

Status: Planned

## Summary

Prevent Traveller's `CACHE_THEN_NETWORK` query from showing a load-error toast
when the same current query has already delivered usable cached tasks. Preserve
the existing visible error for queries that fail before any successful result.

## Problem Frame

`ParseQuery.CachePolicy.CACHE_THEN_NETWORK` may invoke one callback twice. The
current callback replaces the adapter after a successful cache delivery, but a
later network error still enters the generic error branch and tells the user
that loading failed. That message contradicts the populated list and makes an
offline refresh look unsuccessful even though Traveller has usable data.

## Requirements

- **R1:** A current query must continue to replace the adapter whenever it
  receives a successful non-null task list.
- **R2:** A later error from that same callback must not show a load-error toast
  after at least one successful task delivery.
- **R3:** A non-cache-miss error before any successful delivery must still show
  the existing load-error toast.
- **R4:** Cache misses, stopped activities, superseded data generations, and
  null adapters must retain their existing suppression behavior.
- **R5:** The portable checker and documentation must fail closed if the
  success-before-error distinction is removed or inverted.

## Key Technical Decisions

- Track successful delivery inside the individual `FindCallback` instance so
  state cannot leak across refreshes or lifecycle generations.
- Mark delivery only after the callback receives both a null error and a
  non-null task list; malformed or failed callbacks must not suppress a later
  actionable failure.
- Keep the existing generation and lifecycle guard first, ensuring stale
  callbacks cannot mutate either the adapter or the per-query delivery state.

## Implementation Units

### U1: Track successful results per Parse query

**Goal:** Distinguish a later network failure from a first-delivery failure.

**Requirements:** R1, R2, R3, R4

**Dependencies:** None

**Files:**

- `traveller-android-app/traveller/src/main/java/com/requestlabs/traveller/MainActivity.java`
- `scripts/check-baseline.sh`

**Approach:** Add callback-local successful-delivery state, set it after a
successful task list is applied, and require that no success has occurred
before showing the existing non-cache-miss error toast. Preserve the current
lifecycle and data-generation ordering.

**Patterns to follow:** Existing callback-local generation captures and the
cache-miss suppression contract in `MainActivity.updateData`.

**Test scenarios:**

- A successful non-null task list replaces the adapter and records delivery.
- A later non-cache-miss error on the same callback does not show a toast.
- A first non-cache-miss error still shows the load-error toast.
- A cache miss remains silent before or after a successful delivery.
- A stopped or superseded callback returns before changing delivery state or
  UI state.

**Verification:** Portable contracts prove the state is callback-local, success
is recorded only after adapter replacement, and the toast branch requires both
an actionable error and no prior successful delivery.

### U2: Record the user-visible boundary

**Goal:** Keep offline/cache behavior and verification claims understandable.

**Requirements:** R5

**Dependencies:** U1

**Files:**

- `README.md`
- `SECURITY.md`
- `CHANGES.md`
- `docs/plans/2026-06-15-traveller-cache-success-error-suppression.md`

**Approach:** Document that cached tasks remain usable and suppress a later
network-error toast, while first-delivery failures remain visible. Record only
the local, mutation, and hosted evidence actually obtained.

**Test scenarios:** Documentation and completed-plan mutations must be rejected
by the portable checker.

**Verification:** Repository guidance, changelog, and the completed plan agree
with the implemented boundary and do not claim emulator, device, or live Parse
execution unless it occurs.

## Scope Boundaries

In scope:

- Error presentation for the two-delivery `CACHE_THEN_NETWORK` callback.
- Portable, mutation-sensitive contracts and matching documentation.

Deferred to follow-up work:

- Parse SDK or Android Gradle modernization.
- Changes to cache policy, query ordering, persistence, or optimistic saves.
- Emulator, physical-device, and live Parse verification beyond the existing
  device checklist.

## Risks And Dependencies

- The repository uses Parse 1.5.0 and a legacy Android toolchain, so the local
  SDK-free checker is the primary executable contract when a compatible Android
  SDK is unavailable.
- Suppression must remain callback-local; activity-wide state could hide an
  unrelated query failure.
- The exact current-query guard must remain ahead of all state changes.

## Acceptance Examples

- **AE1:** Cache returns tasks, then the network request fails: tasks remain
  visible and no load-error toast appears.
- **AE2:** Cache is unavailable and the network request fails: the existing
  load-error toast appears once the actionable failure is delivered.
- **AE3:** An older query succeeds or fails after a newer refresh begins: the
  older callback changes neither the list nor error presentation.
