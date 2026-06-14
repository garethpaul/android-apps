# Traveller Device Verification Checklist

Status: In Progress

## Problem

Portable contracts cover Traveller's Parse query, optimistic mutation, save
generation, and lifecycle guards, but no checklist defines the emulator/device
and test-backend evidence required before claiming runtime behavior.

## Requirements

1. Add an exact-commit matrix for build, configuration, cache/network queries,
   create/toggle saves, concurrency, lifecycle, offline recovery, and failures.
2. Require sanitized toolchain, emulator/device, backend, result, and log evidence.
3. Keep repository checks separate from unexecuted Android and Parse scenarios.
4. Add mutation-sensitive contracts for the checklist and completion evidence.

## Scope Boundaries

- Do not modernize Gradle, Android APIs, Parse, or dependencies.
- Do not add Parse credentials, backend data, APKs, logs, or device exports.
- Do not claim emulator, device, or live Parse execution from portable checks.
- Do not merge or close stacked pull requests without explicit authorization.

## Verification

- Pending implementation and bounded repository validation.
