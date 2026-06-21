#!/usr/bin/env sh
set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
WORKFLOW_FILE="$ROOT_DIR/.github/workflows/check.yml"
WRAPPER_FILE="$ROOT_DIR/traveller-android-app/gradle/wrapper/gradle-wrapper.properties"
ROOT_BUILD_FILE="$ROOT_DIR/traveller-android-app/build.gradle"

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

printf '%s\n' "Traveller Gradle toolchain workflow checks passed."
