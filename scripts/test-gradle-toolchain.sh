#!/usr/bin/env sh
set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
WORKFLOW_FILE="$ROOT_DIR/.github/workflows/check.yml"
WRAPPER_FILE="$ROOT_DIR/traveller-android-app/gradle/wrapper/gradle-wrapper.properties"
ROOT_BUILD_FILE="$ROOT_DIR/traveller-android-app/build.gradle"
APP_BUILD_FILE="$ROOT_DIR/traveller-android-app/traveller/build.gradle"
GRADLE_PROPERTIES="$ROOT_DIR/traveller-android-app/gradle.properties"

require_file() {
  if [ ! -f "$1" ]; then
    printf '%s\n' "Required toolchain file is missing: $1" >&2
    exit 1
  fi
}

require_contains() {
  file=$1
  pattern=$2
  message=$3

  if ! grep -Fq "$pattern" "$file"; then
    printf '%s\n' "$message" >&2
    exit 1
  fi
}

require_absent() {
  file=$1
  pattern=$2
  message=$3

  if grep -Fq "$pattern" "$file"; then
    printf '%s\n' "$message" >&2
    exit 1
  fi
}

require_file "$WORKFLOW_FILE"
require_file "$WRAPPER_FILE"
require_file "$ROOT_BUILD_FILE"
require_file "$APP_BUILD_FILE"
require_file "$GRADLE_PROPERTIES"

require_contains "$WRAPPER_FILE" \
  "distributionUrl=https\\://services.gradle.org/distributions/gradle-4.1-all.zip" \
  "Traveller must use the audited Gradle 4.1 wrapper for Java 8 hosted builds."
require_contains "$WRAPPER_FILE" \
  "distributionSha256Sum=5c07b3bac2209fbc98fb1fdf6fd831f72429cdf8c503807404eae03d8c8099e5" \
  "Traveller must pin the official Gradle 4.1 all.zip checksum."
require_absent "$WRAPPER_FILE" \
  "gradle-1.10-all.zip" \
  "Hosted Traveller validation must not run the Java 7/TLS-failing Gradle 1.10 wrapper."
require_contains "$ROOT_BUILD_FILE" \
  "classpath 'com.android.tools.build:gradle:3.0.1'" \
  "Traveller must use Android Gradle Plugin 3.0.1 for the Java 8 hosted build."
require_absent "$ROOT_BUILD_FILE" \
  "com.android.tools.build:gradle:0.8.3" \
  "Hosted Traveller validation must not use the Java 7/TLS-failing Android Gradle Plugin 0.8.3 baseline."
require_contains "$APP_BUILD_FILE" \
  "compileSdkVersion 19" \
  "Traveller must keep the legacy compile SDK 19 contract."
require_contains "$APP_BUILD_FILE" \
  "targetSdkVersion 19" \
  "Traveller must keep the legacy target SDK 19 runtime contract."
require_contains "$GRADLE_PROPERTIES" \
  "android.enableAapt2=false" \
  "Traveller must use the AGP 3.0.1 legacy AAPT path for appcompat-v7 19.1.0 resource linking."
require_absent "$GRADLE_PROPERTIES" \
  "android.enableAapt2=true" \
  "Traveller must not re-enable AAPT2 for appcompat-v7 19.1.0 resource linking."

if grep -Fq "gradle-4.1-all.zip" "$WRAPPER_FILE" &&
  grep -Fq "java-version: '7'" "$WORKFLOW_FILE"; then
  printf '%s\n' "Gradle 4.1 migration must not keep hosted Java 7." >&2
  exit 1
fi

require_contains "$WORKFLOW_FILE" \
  "actions/setup-java@c5195efecf7bdfc987ee8bae7a71cb8b11521c00" \
  "GitHub Actions workflow must keep setup-java pinned."
require_contains "$WORKFLOW_FILE" \
  "distribution: zulu" \
  "GitHub Actions workflow must keep the pinned Zulu distribution."
require_contains "$WORKFLOW_FILE" \
  "java-version: '8'" \
  "GitHub Actions workflow must run Gradle 4.1 with Java 8."
require_absent "$WORKFLOW_FILE" \
  "java-version: '7'" \
  "GitHub Actions workflow must not retain the Java 7 TLS-failing gate."
require_contains "$WORKFLOW_FILE" \
  '"$sdkmanager" '\''platforms;android-19'\'' '\''build-tools;26.0.2'\''' \
  "GitHub Actions workflow must provision exactly Android API 19 plus build-tools 26.0.2."
platform_packages=$(grep -Eo 'platforms;android-[0-9]+' "$WORKFLOW_FILE" | sort -u | tr '\n' ' ' | sed 's/[[:space:]]*$//')
if [ "$platform_packages" != "platforms;android-19" ]; then
  printf '%s\n' "GitHub Actions workflow must provision only Android API 19; found: $platform_packages" >&2
  exit 1
fi

printf '%s\n' "Traveller Gradle toolchain workflow checks passed."
