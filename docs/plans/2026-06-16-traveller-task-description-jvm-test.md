# Traveller Task Description JVM Test

## Status: Completed

## Context

Traveller trims task descriptions and rejects empty input, but the behavior is
embedded in an Android Activity and the canonical `make test` target executes
only static repository checks. A pure string normalizer can preserve the UI
behavior while making its boundaries executable on a standard JDK.

## Priority

Add a real, portable behavioral test for task creation input without requiring
an Android SDK, emulator, Parse credentials, or network service.

## Requirements

- Extract null-safe task-description normalization into a package-local pure
  Java class used by `MainActivity`.
- Test null, empty, whitespace-only, trimmed ASCII, and trimmed Unicode content
  through a dependency-free JVM runner.
- Compile production and test sources into a temporary directory and remove it
  on success or failure.
- Make `make test` execute the JVM test while retaining the static baseline in
  `make lint` and the optional Android build boundary in `make build`.
- Pin the hosted JDK setup action and disable persisted checkout credentials.
- Add mutation-sensitive contracts for application wiring, cases, compiler and
  runner commands, cleanup, workflow, documentation, and completed evidence.

## Verification

- Repository and external-directory `make test` and `make check`.
- Mutations covering class wiring, null behavior, trimming, test cases,
  temporary cleanup, workflow setup, guidance, and plan status.
- Shell syntax, exact-diff, generated-artifact, credential-pattern, and
  whitespace audits.

## Results

- Repository and external-directory `make test` and `make check` passed.
- Eleven hostile mutations were rejected across Activity wiring, null and trim
  behavior, executable cases, temporary cleanup, Make integration, hosted JDK
  setup, documentation, and completed plan evidence.
- `make build` reported its expected skip because no Android SDK or local
  Traveller constants are configured in this environment.
- No Android SDK, emulator, physical-device, or live Parse scenario was executed.

## Scope Boundary

This change does not alter Parse requests, save callbacks, lifecycle state,
adapter behavior, Android layouts, credentials, Gradle dependencies, or device
behavior.
