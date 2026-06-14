# Traveller Make Root Override Protection

Status: Completed

## Problem

The Makefile derives the repository root from its own location, but GNU Make
command-line variables override an ordinary assignment. A caller can supply a
hostile `ROOT` value and redirect the SDK-free baseline scripts, constants
lookup, and conditional Gradle build away from the reviewed checkout.

## Requirements

1. Protect the Makefile-derived root with GNU Make's `override` directive.
2. Preserve every existing target, constants path, SDK skip condition, and
   Gradle command.
3. Require exact protected-root, rooted script, rooted constants, and rooted
   Gradle contracts in the dependency-free baseline checker.
4. Pass local, external-directory, and hostile-root `make check` gates.
5. Reject focused root, script, constants, Gradle, and completed-plan
   mutations.

## Verification

- Run shell syntax and the dependency-free baseline checker first.
- Run bounded local, external-directory, and hostile command-line `ROOT`
  `make check` gates, recording whether the Android SDK-backed build executes
  or truthfully skips.
- Run focused mutations plus workflow YAML, SVG XML, artifact, whitespace,
  conflict-marker, and changed-line credential audits.

## Scope Boundaries

- Do not change Traveller runtime behavior, Parse configuration, dependencies,
  workflows, Android sources, resources, or deployment configuration.
- Do not create placeholder credentials or claim emulator, device, or live
  Parse verification.
- Do not merge or close any pull request without explicit owner authorization.

## Work Completed

- Protected the Makefile-derived root while preserving all existing targets,
  skip conditions, constants lookup, and Gradle behavior.
- Added dependency-free contracts for the exact protected assignment, rooted
  constants and scripts, rooted Gradle command, and this completed plan.

## Verification Results

- The focused baseline checker and shell syntax checks passed.
- Local, external-directory, and hostile command-line `ROOT` `make check`
  gates each passed both baseline executions and shell syntax checks while
  remaining anchored to this checkout.
- The Android SDK and ignored local `Constants.java` were absent, so all three
  gates truthfully reported the designed Gradle-build skip; no SDK-backed
  compile, lint, emulator, device, or live Parse result is claimed.
- All nine focused mutations were rejected: missing `override`, `CURDIR`,
  recursive root assignment, `firstword`, unrooted constants, one unrooted
  baseline command, unrooted helper, unrooted Gradle command, and reopened plan
  status.
- Workflow YAML, Android XML, SVG XML, shell syntax, conflict-marker,
  whitespace, ignored-artifact, exact-diff, and changed-line credential audits
  passed; only the three intended files changed and no generated artifacts
  remained.
