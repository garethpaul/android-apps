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
  "distributionUrl=https\\://services.gradle.org/distributions/gradle-1.10-all.zip" \
  "Traveller must keep the audited Gradle 1.10 wrapper unless the toolchain contract is revised."
require_contains "$ROOT_BUILD_FILE" \
  "classpath 'com.android.tools.build:gradle:0.8.3'" \
  "Traveller must keep the audited Android Gradle Plugin 0.8.3 baseline."

if grep -Fq "gradle-1.10-all.zip" "$WRAPPER_FILE" &&
  grep -Fq "java-version: '8'" "$WORKFLOW_FILE"; then
  printf '%s\n' "Gradle 1.10 must not be paired with hosted Java 8." >&2
  exit 1
fi

require_contains "$WORKFLOW_FILE" \
  "actions/setup-java@c5195efecf7bdfc987ee8bae7a71cb8b11521c00" \
  "GitHub Actions workflow must keep setup-java pinned."
require_contains "$WORKFLOW_FILE" \
  "distribution: zulu" \
  "GitHub Actions workflow must select a distribution that publishes hosted Java 7."
require_contains "$WORKFLOW_FILE" \
  "java-version: '7'" \
  "GitHub Actions workflow must run Gradle 1.10 with Java 7."
require_absent "$WORKFLOW_FILE" \
  "distribution: temurin" \
  "Temurin does not provide the required Java 7 hosted toolchain."
require_absent "$WORKFLOW_FILE" \
  "java-version: '8'" \
  "Gradle 1.10 is not compatible with a hosted Java 8 build gate."

printf '%s\n' "Traveller Gradle toolchain workflow checks passed."
