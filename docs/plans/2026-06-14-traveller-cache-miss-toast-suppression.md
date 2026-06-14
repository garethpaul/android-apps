# Traveller Cache-Miss Toast Suppression

Status: Completed

## Context

Traveller uses Parse 1.5.0 with `CACHE_THEN_NETWORK`. The vendored SDK invokes
the callback for `CACHE_ONLY` and then always starts `NETWORK_ONLY`; an empty
cache therefore reports `ParseException.CACHE_MISS` before the network result.
The current callback treats that expected intermediate state as a user-visible
load failure and can show a misleading toast immediately before valid data.

## Scope

- Suppress only `ParseException.CACHE_MISS` in the task-loading callback.
- Preserve successful cache and network results, real load errors, lifecycle
  and generation guards, adapter replacement, and localized messaging.
- Keep `CACHE_THEN_NETWORK` and the vendored Parse 1.5.0 dependency unchanged.
- Add mutation-sensitive source, ordering, documentation, and plan contracts.

## Verification Plan

- Verify the vendored Parse bytecode exposes `CACHE_MISS` and sequences
  `CACHE_ONLY` before `NETWORK_ONLY` for `CACHE_THEN_NETWORK`.
- Run root and external-working-directory `make check`.
- Reject isolated mutations that remove or reorder the cache-miss guard,
  change the cache policy, weaken documentation, or reopen the completed plan.
- Audit the exact diff, generated artifacts, conflict markers, whitespace, and
  credential-shaped additions before commit and push.

## Risks

- A cache-miss-only deployment would defer visible failure until the network
  callback, which is the actual terminal result for this policy.
- This change does not alter query data, retries, persistence, credentials,
  adapter generations, or save reconciliation.

## Verification

Completed on 2026-06-14:

- `javap` against vendored Parse 1.5.0 confirmed `CACHE_MISS` is code 120 and
  `CACHE_THEN_NETWORK` invokes `CACHE_ONLY` before `NETWORK_ONLY`.
- Root SDK-backed and external-working-directory SDK-free `make check` passed.
- Five isolated hostile mutations were rejected across the cache policy,
  exception-code guard, guard ordering, documentation, and completed-plan
  status.
- The exact diff, generated-artifact, whitespace, conflict-marker, and
  credential-pattern audits passed before commit.
