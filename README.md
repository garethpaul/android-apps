# android-apps

<!-- README-OVERVIEW-IMAGE -->
![Project overview](docs/readme-overview.svg)

## Overview

`garethpaul/android-apps` is an Android application or sample. Personal Android Apps

This README is based on the checked-in source, manifests, scripts, and repository metadata on the `master` branch. The project language mix found during review was: Java (4), shell (1).

## Repository Contents

- `README.md` - project overview and local usage notes
- `.github/workflows/check.yml` - CI baseline that runs the root Make gate
- `docs` - source or example code
- `scripts` - source or example code
- `SECURITY.md` - security reporting and disclosure guidance
- `traveller-android-app` - source or example code
- `VISION.md` - project direction and maintenance guardrails

Additional scan context:

- Source directories: docs, scripts, traveller-android-app
- Dependency and build manifests: none detected
- Entry points or build surfaces: Gradle build files
- Test-looking files: no obvious test files detected

## Getting Started

### Prerequisites

- Git
- Android Studio or a compatible Android SDK
- Gradle or the checked-in Gradle wrapper when present

### Setup

```bash
git clone https://github.com/garethpaul/android-apps.git
cd android-apps
make check
make lint
make test
make build
scripts/check-baseline.sh
scripts/prepare-traveller-constants.sh
cd traveller-android-app
./gradlew lint --no-daemon
./gradlew check --no-daemon
./gradlew assembleDebug --no-daemon
```

The setup commands above are derived from repository files. Legacy mobile, Python, or JavaScript samples may require older SDKs or package versions than a modern workstation uses by default.

## Running or Using the Project

- Use Android Studio to open the project or run `gradle assembleDebug` when the Android SDK is configured.

## Testing and Verification

- `make lint` - checks shell script syntax and runs the SDK-free Traveller baseline checks
- `make test` - runs the SDK-free Traveller baseline checks
- `make build` - attempts the legacy Traveller Gradle debug build when Android SDK configuration and local constants are present; otherwise it reports a skip
- `make check` - repository-standard wrapper around `make lint`, `make test`, and `make build`
- `scripts/check-baseline.sh` - runs SDK-free Traveller baseline checks
- The baseline check also protects source-level contracts for Traveller row
  inflation, Parse subclass registration, and task input normalization.
- From `traveller-android-app/`, run `./gradlew lint --no-daemon`, `./gradlew check --no-daemon`, and `./gradlew assembleDebug --no-daemon` when the Android SDK is configured
- GitHub Actions runs the same root `make check` gate through
  `.github/workflows/check.yml` on pushes, pull requests, and manual runs with
  pinned checkout, read-only permissions, a fixed Ubuntu 24.04 runner,
  superseded-run cancellation, and a five-minute timeout.

When the required SDK or runtime is unavailable, use static checks and source review first, then verify on a machine that has the matching platform toolchain.

## Configuration and Secrets

- Detected references to Parse. Keep API keys, OAuth credentials, tokens, and account-specific values in local configuration only.
- Traveller is pinned to Android build-tools 24.0.3 for this legacy baseline.
- Copy `Constants.java.example` with `scripts/prepare-traveller-constants.sh`, then replace placeholder Parse values locally. `Constants.java` must stay ignored.
- Traveller fails before `Parse.initialize` when either local Parse value is
  blank or still matches the checked-in template placeholder. The diagnostic
  never includes configured credential values.
- Traveller preserves the Android `Application` lifecycle by calling
  `super.onCreate()` before configuration validation and Parse initialization.
- Traveller trims task descriptions and rejects whitespace-only entries before
  saving Parse `Item` records.
- Traveller treats a missing task input view as an empty description so stale
  layouts do not crash task creation.
- Traveller ignores item toggle events when the adapter, selected item, row
  view, or row text view is unavailable or malformed.
- Traveller ignores item toggle events whose adapter position is outside the
  current list bounds.
- Traveller row rendering tolerates missing items, missing descriptions, and
  malformed row text views without crashing the list adapter.
- Traveller disables Android backup in the checked-in manifest so local Parse
  state is not included in platform backups by default.
- Traveller shows a localized error toast when Parse task loading fails instead
  of silently leaving stale or empty list state.
- Local IDE metadata stays ignored, including nested Android Studio project
  metadata, so editor workspace files do not become part of the shared
  Traveller baseline.

## Security and Privacy Notes

- Review changes touching external API calls or credential-adjacent configuration; examples from the scan include traveller-android-app/traveller/src/main/java/com/requestlabs/traveller/App.java.
- Review changes touching network requests, sockets, or service endpoints; examples from the scan include scripts/check-baseline.sh, traveller-android-app/build.gradle, traveller-android-app/gradle.properties, traveller-android-app/traveller/proguard-rules.txt, and 4 more.
- Review changes touching mobile permissions or privacy-sensitive device data; examples from the scan include docs/plans/2026-06-08-traveller-android-reproducibility-baseline.md, traveller-android-app/gradlew, traveller-android-app/traveller/src/main/AndroidManifest.xml.
- Review changes touching file, media, JSON, XML, CSV, OCR, or data parsing; examples from the scan include docs/plans/2026-06-08-traveller-android-reproducibility-baseline.md, scripts/check-baseline.sh, traveller-android-app/traveller/build.gradle, traveller-android-app/traveller/lint.xml, and 6 more.
- Review changes touching database, model, or persistence code; examples from the scan include docs/plans/2026-06-08-traveller-android-reproducibility-baseline.md.

## Maintenance Notes

- This looks like a legacy Android project or sample. Expect Android SDK, Gradle, and support-library versions to matter.
- See `CHANGES.md` and `docs/plans/2026-06-08-traveller-constants-helper.md`
  for the current constants-helper baseline.
- See `docs/plans/2026-06-09-traveller-task-input-normalization.md` for the
  task input normalization contract.
- See `docs/plans/2026-06-09-traveller-task-input-null-guard.md` for the task
  input null guard.
- See `docs/plans/2026-06-09-traveller-item-toggle-guards.md` for item-toggle
  null guards.
- See `docs/plans/2026-06-09-traveller-item-toggle-position-guard.md` for
  stale adapter-position guards.
- See `docs/plans/2026-06-09-traveller-item-row-rendering-guards.md` for item
  row rendering guards.
- See `docs/plans/2026-06-09-traveller-backup-policy.md` for the manifest
  backup policy contract.
- See `docs/plans/2026-06-09-traveller-parse-query-failures.md` for the task
  loading failure contract.
- See `docs/plans/2026-06-09-traveller-make-gate-targets.md` for the
  repository lint, test, and build target contract.
- See `docs/plans/2026-06-09-traveller-editor-metadata-ignore.md` for the
  local editor metadata ignore contract.
- See `docs/plans/2026-06-09-traveller-nested-editor-metadata-cleanup.md` for
  nested Android Studio metadata cleanup.
- See `docs/plans/2026-06-10-ci-baseline.md` for the lightweight CI baseline.
- See `SECURITY.md` for vulnerability reporting and safe research guidance.
- See `VISION.md` for project direction and contribution guardrails.

## Contributing

Keep changes small and tied to the project that is already present in this repository. For code changes, document the toolchain used, avoid committing generated dependency directories or local configuration, and update this README when setup or verification steps change.
