#!/usr/bin/env sh
set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
ROOT_BUILD_FILE="$ROOT_DIR/traveller-android-app/build.gradle"
WRAPPER_FILE="$ROOT_DIR/traveller-android-app/gradle/wrapper/gradle-wrapper.properties"
WORKFLOW_FILE="$ROOT_DIR/.github/workflows/check.yml"

require_file() {
  if [ ! -f "$1" ]; then
    printf '%s\n' "Required Gradle dependency-resolution file is missing: $1" >&2
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

require_file "$ROOT_BUILD_FILE"
require_file "$WRAPPER_FILE"
require_file "$WORKFLOW_FILE"

require_contains "$WRAPPER_FILE" \
  "distributionUrl=https\\://services.gradle.org/distributions/gradle-1.10-all.zip" \
  "Traveller must keep the audited Gradle 1.10 wrapper unless the dependency contract is revised."
require_contains "$ROOT_BUILD_FILE" \
  "classpath 'com.android.tools.build:gradle:0.8.3'" \
  "Traveller must keep the audited Android Gradle Plugin 0.8.3 baseline."
require_contains "$WORKFLOW_FILE" \
  "java-version: '7'" \
  "Hosted Traveller validation must keep the Java 7 Gradle 1.10 contract."

require_absent "$ROOT_BUILD_FILE" \
  "repo1.maven.org" \
  "repo1.maven.org failed hosted Java 7 Gradle 1.10 dependency resolution with peer authentication errors."
require_absent "$ROOT_BUILD_FILE" \
  "http://" \
  "Traveller Gradle dependency resolution must not use insecure HTTP repositories."
require_absent "$ROOT_BUILD_FILE" \
  "mavenCentral()" \
  "Gradle 1.10 mavenCentral() must not hide the repository transport endpoint."
require_contains "$ROOT_BUILD_FILE" \
  "url 'https://repo.maven.apache.org/maven2'" \
  "Hosted Java 7 Gradle resolution must use Maven Central's canonical HTTPS endpoint, not repo1.maven.org."

canonical_count=$(grep -Fc "url 'https://repo.maven.apache.org/maven2'" "$ROOT_BUILD_FILE")
if [ "$canonical_count" -ne 2 ]; then
  printf '%s\n' "Traveller must declare exactly two canonical Maven Central HTTPS repositories." >&2
  exit 1
fi

printf '%s\n' "Traveller Gradle dependency-resolution checks passed."
