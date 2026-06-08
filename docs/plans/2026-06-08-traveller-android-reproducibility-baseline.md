---
title: Traveller Android Reproducibility Baseline
type: chore
status: completed
date: 2026-06-08
---

# Traveller Android Reproducibility Baseline

## Summary

Raise the engineering baseline for the legacy Traveller Android app by making dependency resolution deterministic, removing an insecure Gradle wrapper URL, pinning an installable SDK-19 build-tools version, documenting the missing local configuration required by the Parse-backed app, and adding a lightweight source check that can run before a compatible Android SDK is configured.

---

## Problem Frame

The repository is a 2014-era Android project with Gradle 1.10, Android Gradle Plugin 0.8.x, Parse 1.5.0, dynamic dependency versions, and almost no setup documentation. A broad Android migration is high risk without a reproducible starting point, especially because this environment does not provide the compatible SDK 19/build-tools 19 setup the project expects and the app depends on an ignored `Constants.java` file for Parse credentials.

---

## Requirements

- R1. Gradle plugin and Android support dependencies must avoid dynamic `+` versions so repeated builds resolve the same tooling.
- R2. `traveller-android-app/gradlew` must be executable so standard Gradle commands can start.
- R3. The Gradle wrapper distribution URL and Maven repository URLs must use HTTPS instead of HTTP.
- R4. The README must document the nested project path, legacy SDK/build-tools expectations, Parse credential file requirement, and local verification commands.
- R5. The repository must include a safe Parse credential template without committing real credentials.
- R6. A local source check must run without compatible Android SDK installation and verify the reproducibility baseline, including the pinned build-tools version.
- R7. Local verification results must distinguish source-check success from Android SDK/toolchain prerequisites.
- R8. Larger migrations to modern Android Gradle Plugin, AndroidX, maintained Parse alternatives, and real Android tests must remain explicit follow-up work.

---

## Key Technical Decisions

- **Pin only the legacy coordinates:** Use fixed versions compatible with compile SDK 19 instead of migrating the Android toolchain in the same pass.
- **Use an installable SDK-19 build-tools pin:** Use build-tools 19.1.0 because it is the SDK-19-era package available from the current SDK manager.
- **Use HTTPS without changing Gradle:** Keeping Gradle 1.10 avoids widening the change while removing avoidable wrapper and Maven transport risks.
- **Keep Parse secrets out of git:** Provide `Constants.java.example` and keep real `Constants.java` ignored.
- **Add SDK-free checks:** A shell script can validate pinned dependency declarations and required template/docs even when `./gradlew` cannot configure without a compatible Android SDK.
- **Document follow-up modernization separately:** Parse 1.5.0, appcompat 19.x, and Android Gradle Plugin 0.8.x are obsolete, but updating them requires an Android-capable verification pass.

---

## Scope Boundaries

- This pass does not migrate to a newer Gradle wrapper or Android Gradle Plugin.
- This pass does not replace Parse, appcompat, or the bundled Parse jar.
- This pass does not commit real Parse application credentials.
- This pass does not change app runtime behavior.
- This pass does not add Android instrumentation tests or emulator coverage.

---

## Implementation Units

### U1. Pin Legacy Build Inputs

- **Goal:** Make the existing Gradle build resolve fixed legacy versions.
- **Files:** `traveller-android-app/gradlew`, `traveller-android-app/build.gradle`, `traveller-android-app/traveller/build.gradle`, `traveller-android-app/gradle/wrapper/gradle-wrapper.properties`
- **Patterns:** Keep the existing Gradle 1.10 / Android Gradle Plugin 0.8 project shape; replace only dynamic versions, executable mode, and transport URLs.
- **Test Scenarios:**
  - `traveller-android-app/gradlew` is executable.
  - `traveller-android-app/build.gradle` no longer contains `com.android.tools.build:gradle:0.8.+`.
  - `traveller-android-app/build.gradle` uses an HTTPS Maven Central URL.
  - `traveller-android-app/traveller/build.gradle` no longer contains `appcompat-v7:+`.
  - `traveller-android-app/traveller/build.gradle` pins build-tools 19.1.0.
  - `traveller-android-app/gradle/wrapper/gradle-wrapper.properties` uses an HTTPS distribution URL.
- **Verification:** `scripts/check-baseline.sh`, `cd traveller-android-app && ./gradlew tasks --no-daemon`

### U2. Document Parse Credential Setup

- **Goal:** Make a fresh checkout understandable without exposing secrets.
- **Files:** `README.md`, `traveller-android-app/traveller/src/main/java/com/requestlabs/traveller/Constants.java.example`, `.gitignore`
- **Patterns:** Keep real `Constants.java` ignored; provide a checked-in adjacent example with placeholder values.
- **Test Scenarios:**
  - README explains copying `Constants.java.example` to `Constants.java`.
  - README states that real Parse values remain local and untracked.
  - `.gitignore` continues to ignore the real credentials file.
- **Verification:** `scripts/check-baseline.sh` and manual README review

### U3. Add SDK-Free Baseline Check

- **Goal:** Provide a repeatable quality gate that works before Android SDK setup.
- **Files:** `scripts/check-baseline.sh`
- **Patterns:** POSIX shell with repo-root detection; fail fast with clear messages.
- **Test Scenarios:**
  - The script fails if dynamic Gradle versions are reintroduced.
  - The script fails if the wrapper distribution URL reverts to HTTP.
  - The script fails if the Gradle wrapper is not executable.
  - The script fails if the Parse credential template or README setup notes are missing.
  - The script succeeds in this environment without compatible Android SDK configuration.
- **Verification:** `scripts/check-baseline.sh`

### U4. Developer Documentation Refresh

- **Goal:** Record the current baseline and safe follow-up path.
- **Files:** `README.md`
- **Patterns:** Short command-oriented sections for setup, credentials, verification, and deferred modernization.
- **Test Scenarios:**
  - README lists `scripts/check-baseline.sh`.
  - README lists `cd traveller-android-app && ./gradlew tasks --no-daemon`.
  - README lists Android build-tools 19.1.0.
  - README explains that Android SDK prerequisites are required before Gradle verification can pass.
  - README identifies Parse and Android toolchain modernization as future work.
- **Verification:** Manual README review

---

## Risks & Dependencies

- Android Gradle Plugin 0.8.x, Gradle 1.10, appcompat 19.x, and Parse 1.5.0 are obsolete and may require old JDK/SDK combinations.
- Local Android verification is expected to fail in this environment until `ANDROID_HOME` or `local.properties` points at a compatible SDK.
- The app currently depends on a local `Constants.java` file for Parse credentials; the template improves setup clarity but intentionally does not make the app runnable without real credentials.

---

## Sources / Research

- `traveller-android-app/build.gradle` contains the dynamic Android Gradle Plugin version and previously used Gradle 1.10's HTTP `mavenCentral()` default.
- `traveller-android-app/traveller/build.gradle` contains the dynamic appcompat dependency and bundled Parse jar.
- `traveller-android-app/gradle/wrapper/gradle-wrapper.properties` previously used an HTTP Gradle distribution URL and now uses HTTPS.
- `traveller-android-app/gradlew` was tracked as mode `100644`, so direct execution failed with permission denied.
- `traveller-android-app/traveller/src/main/java/com/requestlabs/traveller/App.java` references the ignored `Constants.java` Parse credential file.
- `.gitignore` currently ignores `Constants.java` and `Constants.class`.
