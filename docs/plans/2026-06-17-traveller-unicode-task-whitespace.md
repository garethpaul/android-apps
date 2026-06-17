# Traveller Unicode Task Whitespace

## Status: Planned

## Problem

Traveller documents that whitespace-only task descriptions are rejected, but
the pure normalizer uses `String.trim()`. That method removes only characters
at or below U+0020, so descriptions containing only common Unicode spacing
characters such as non-breaking, em, or ideographic spaces can still be saved.

## Priority

P1: make the existing task-description boundary honor its documented
whitespace-only contract without changing Parse, lifecycle, adapter, or Android
UI behavior.

## Requirements

1. Preserve the null-safe empty result and every boundary character removed by
   the existing `String.trim()` behavior.
2. Also remove leading and trailing characters recognized by
   `Character.isWhitespace` or `Character.isSpaceChar`.
3. Reject descriptions containing only ASCII or Unicode boundary whitespace.
4. Preserve interior spacing, Unicode content, and the original normalized
   string value when no boundary whitespace is present.
5. Keep the implementation package-local, dependency-free, and executable by
   the existing standard-JDK test runner.
6. Extend runtime tests, static baseline contracts, maintained guidance,
   changelog, and this plan with truthful completed evidence.

## Implementation Units

### U1: Extend Pure Normalization

**File:** `traveller-android-app/traveller/src/main/java/com/requestlabs/traveller/TaskDescriptionNormalizer.java`

Replace `String.trim()` with explicit leading and trailing indexes backed by a
small whitespace predicate that preserves the old U+0020 boundary and adds the
standard Java Unicode whitespace and space-character classifications.

### U2: Add Executable Regressions

**File:** `traveller-android-app/traveller/src/test/java/com/requestlabs/traveller/TaskDescriptionNormalizerTest.java`

Cover Unicode-space-only input, Unicode boundary trimming, preserved interior
non-breaking spaces, and legacy control-character trimming.

### U3: Preserve Durable Evidence

**Files:** `scripts/check-baseline.sh`, `README.md`, `SECURITY.md`, `VISION.md`,
`CHANGES.md`, `AGENTS.md`, and this plan.

Require the predicate, both Unicode classifiers, boundary loops, focused JVM
cases, maintained guidance, completed status, and actual verification.

## Verification

- Observe the new JVM cases fail before implementation.
- Run the focused JVM runner, repository and external-directory `make test`,
  and repository and external-directory `make check` with explicit timeouts.
- Reject isolated hostile mutations for old-boundary preservation, both Unicode
  classifiers, leading and trailing loops, tests, guidance, and plan status.
- Audit the exact diff, generated artifacts, secrets, conflicts, modes,
  dependency/workflow drift, file sizes, and whitespace before commit.

## Scope Boundaries

- Do not change task length policy, interior spacing, case, normalization form,
  Parse requests, save callbacks, lifecycle generations, adapter behavior,
  Android layouts, dependencies, credentials, or CI action pins.
- Android SDK, emulator, physical-device, and live Parse verification remain
  outside this portable boundary.

## Completed Verification

To be recorded after implementation and validation.
