# Traveller Device Verification

Run this matrix on the exact reviewed commit with a compatible Android SDK,
Java, legacy Gradle toolchain, and an authorized non-production Parse backend.
Portable contracts do not substitute for emulator or physical-device evidence.

## Evidence Header

Record these values without Parse credentials, task contents, account IDs,
device identifiers, backend payloads, APKs, or raw logs:

- commit SHA and pull request
- tester and UTC timestamp
- Android Studio, SDK, build tools, Java, and Gradle versions
- emulator image or physical-device model and Android version
- clean install or upgrade path
- sanitized Parse test-backend identifier
- nested Gradle lint, test, and assemble result

Mark each row `pass`, `fail`, `blocked`, or `not run`. Explain every blocked or
unexecuted row. Do not convert `not run` into passing evidence.

## Build And Configuration

| Scenario | Expected result | Result | Evidence |
| --- | --- | --- | --- |
| Placeholder constants | App fails closed before Parse initialization. | not run | |
| Authorized local constants | App starts without logging credential values. | not run | |
| Clean debug build | Lint, tests, and debug assembly complete. | not run | |
| Fresh install | Traveller opens with a usable empty or loaded task list. | not run | |

Generate local constants with the repository helper, verify they remain
untracked, and remove them after testing.

## Query And Mutation Matrix

| Scenario | Expected result | Result | Evidence |
| --- | --- | --- | --- |
| Warm cache then network | Cached rows render, then current network rows reconcile. | not run | |
| Cache miss then network | Intermediate cache miss does not show an error toast. | not run | |
| Offline launch | One actionable load failure appears without backend details. | not run | |
| Create task success | Optimistic row remains after save completion. | not run | |
| Create task failure | Unsaved optimistic row is removed once. | not run | |
| Toggle success | Optimistic completion state remains. | not run | |
| Toggle failure | Prior completion state is restored once. | not run | |
| Repeated same-task saves | Older callbacks cannot overwrite newer state. | not run | |
| Query during local mutation | Older query snapshot cannot replace optimistic state. | not run | |

## Lifecycle Matrix

| Scenario | Expected result | Result | Evidence |
| --- | --- | --- | --- |
| Stop during query | Late callbacks do not mutate UI or show stale errors. | not run | |
| Stop during save | Late save failures do not reconcile a stopped activity. | not run | |
| Rotate during query | Recreated activity accepts only its current generation. | not run | |
| Rotate during save | Old activity callbacks cannot alter the new adapter. | not run | |
| Process recreation | Missing in-memory generations recover through a fresh query. | not run | |

Sanitized logs and screenshots must not contain Parse application IDs, client
keys, task text, backend object IDs, exception payloads, or device identifiers.

## Completion

Record unresolved failures and protected evidence links outside git. A runtime
claim requires all applicable rows to pass on the exact commit. This repository
currently records every Android device and Parse backend row as unexecuted.
