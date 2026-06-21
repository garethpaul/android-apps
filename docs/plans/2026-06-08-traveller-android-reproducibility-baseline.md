---
title: Traveller Android Reproducibility Baseline
type: chore
status: completed
date: 2026-06-08
---

# Traveller Android Reproducibility Baseline

## Summary

Raise the engineering baseline for the legacy Traveller Android app by making dependency resolution deterministic, removing an insecure Gradle wrapper URL, pinning a host-compatible Android build-tools version, documenting the missing local configuration required by the Parse-backed app, and adding a lightweight source check that can run before a compatible Android SDK is configured.

---

## Problem Frame

The repository is a 2014-era Android project with a legacy Parse 1.5.0 app and an intentionally narrow build-system baseline. The baseline originally used Gradle 1.10 and Android Gradle Plugin 0.8.x; hosted Java 7 later failed modern HTTPS dependency authentication, so the maintained baseline now uses Java 8, Gradle 4.1, Android Gradle Plugin 3.0.1, Google Maven before Maven Central, and build-tools 26.0.2 while preserving app source behavior.

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

- **Pin only the legacy app coordinates:** Keep compile and target SDK 19, appcompat 19.1.0, and Parse 1.5.0 fixed while modernizing only the minimum build-system layer needed for hosted HTTPS.
- **Use a host-compatible build-tools pin:** Use build-tools 26.0.2 with Android Gradle Plugin 3.0.1 while compile and target SDK remain at 19.
- **Use maintained HTTPS repositories:** Resolve Android artifacts from Google Maven before Maven Central, with no JCenter or insecure HTTP fallback.
- **Keep Parse secrets out of git:** Provide `Constants.java.example` and keep real `Constants.java` ignored.
- **Add SDK-free checks:** A shell script can validate pinned dependency declarations and required template/docs even when `./gradlew` cannot configure without a compatible Android SDK.
- **Document follow-up modernization separately:** Parse 1.5.0, appcompat 19.x, and Android Gradle Plugin 0.8.x are obsolete, but updating them requires an Android-capable verification pass.

---

## Scope Boundaries

- This pass does not replace Parse, appcompat, or the bundled Parse jar.
- This pass does not commit real Parse application credentials.
- This pass does not change app runtime behavior.
- This pass does not add Android instrumentation tests or emulator coverage.

---

## Implementation Units

### U1. Pin Legacy Build Inputs

- **Goal:** Make the existing Gradle build resolve fixed legacy versions.
- **Files:** `traveller-android-app/gradlew`, `traveller-android-app/build.gradle`, `traveller-android-app/traveller/build.gradle`, `traveller-android-app/gradle/wrapper/gradle-wrapper.properties`
- **Patterns:** Keep the app source and SDK 19 behavior, but use Java 8, Gradle 4.1, Android Gradle Plugin 3.0.1, Google Maven before Maven Central, and AGP 3 DSL.
- **Test Scenarios:**
  - `traveller-android-app/gradlew` is executable.
  - `traveller-android-app/build.gradle` pins `com.android.tools.build:gradle:3.0.1`.
  - `traveller-android-app/build.gradle` declares `google()` before `mavenCentral()` in both repository blocks.
  - `traveller-android-app/build.gradle` does not use `repo1.maven.org`,
    insecure HTTP, JCenter, or ad hoc repository URLs.
  - `traveller-android-app/traveller/build.gradle` no longer contains `appcompat-v7:+`.
  - `traveller-android-app/traveller/build.gradle` pins build-tools 26.0.2.
  - `traveller-android-app/traveller/build.gradle` uses `com.android.application`, `minifyEnabled`, and `implementation`.
  - `traveller-android-app/gradle/wrapper/gradle-wrapper.properties` uses the Gradle 4.1 all.zip HTTPS distribution URL and checksum.
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
  - README lists Android build-tools 26.0.2.
  - README explains that Android SDK prerequisites are required before Gradle verification can pass.
  - README identifies Parse and Android toolchain modernization as future work.
- **Verification:** Manual README review

---

## Risks & Dependencies

- Android Gradle Plugin 3.0.1, Gradle 4.1, appcompat 19.x, and Parse 1.5.0 are obsolete and may require exact hosted SDK/JDK combinations.
- Local Android verification is expected to fail in this environment until `ANDROID_HOME` or `local.properties` points at a compatible SDK.
- The app currently depends on a local `Constants.java` file for Parse credentials; the template improves setup clarity but intentionally does not make the app runnable without real credentials.

---

## Sources / Research

- `traveller-android-app/build.gradle` contains the Android Gradle Plugin version and previously used Gradle 1.10-era repository transport assumptions.
- `traveller-android-app/traveller/build.gradle` contains the dynamic appcompat dependency and bundled Parse jar.
- `traveller-android-app/gradle/wrapper/gradle-wrapper.properties` previously used an HTTP Gradle distribution URL and now uses the verified Gradle 4.1 HTTPS all distribution plus SHA-256 checksum.
- `traveller-android-app/gradlew` was tracked as mode `100644`, so direct execution failed with permission denied.
- `traveller-android-app/traveller/src/main/java/com/requestlabs/traveller/App.java` references the ignored `Constants.java` Parse credential file.
- `.gitignore` currently ignores `Constants.java` and `Constants.class`.
