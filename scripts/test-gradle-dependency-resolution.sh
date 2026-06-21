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
  "distributionUrl=https\\://services.gradle.org/distributions/gradle-4.1-all.zip" \
  "Traveller must use Gradle 4.1 for modern HTTPS dependency resolution."
require_contains "$ROOT_BUILD_FILE" \
  "classpath 'com.android.tools.build:gradle:3.0.1'" \
  "Traveller must resolve Android Gradle Plugin 3.0.1 from Google Maven."
require_contains "$WORKFLOW_FILE" \
  "java-version: '8'" \
  "Hosted Traveller validation must use Java 8 with Gradle 4.1."

require_absent "$ROOT_BUILD_FILE" \
  "repo1.maven.org" \
  "repo1.maven.org failed hosted Java 7 Gradle 1.10 dependency resolution with peer authentication errors."
require_absent "$ROOT_BUILD_FILE" \
  "http://" \
  "Traveller Gradle dependency resolution must not use insecure HTTP repositories."
require_absent "$ROOT_BUILD_FILE" \
  "repo.maven.apache.org" \
  "AGP 3.0.1 and appcompat 19.1.0 must resolve from Google Maven before Maven Central."
require_absent "$ROOT_BUILD_FILE" \
  "jcenter()" \
  "Traveller Gradle dependency resolution must not depend on JCenter."
require_absent "$ROOT_BUILD_FILE" \
  "maven { url" \
  "Traveller Gradle dependency resolution should use built-in HTTPS repositories."
require_contains "$ROOT_BUILD_FILE" \
  "google()" \
  "Traveller Gradle dependency resolution must declare Google Maven."
require_contains "$ROOT_BUILD_FILE" \
  "mavenCentral()" \
  "Traveller Gradle dependency resolution must keep Maven Central for non-Android transitive dependencies."

google_count=$(grep -Fc "google()" "$ROOT_BUILD_FILE")
maven_count=$(grep -Fc "mavenCentral()" "$ROOT_BUILD_FILE")
if [ "$google_count" -ne 2 ] || [ "$maven_count" -ne 2 ]; then
  printf '%s\n' "Traveller must declare exactly two Google Maven and two Maven Central repositories." >&2
  exit 1
fi

if ! awk '
  /repositories[[:space:]]*\{/ {
    in_repositories = 1
    depth = 1
    saw_google = 0
    saw_maven = 0
    next
  }
  in_repositories {
    if (index($0, "{")) depth++
    if (index($0, "}")) depth--
    if (index($0, "mavenCentral()") && !saw_google) bad = 1
    if (index($0, "google()")) saw_google = 1
    if (index($0, "mavenCentral()")) saw_maven = 1
    if (depth == 0) {
      blocks++
      if (!saw_google || !saw_maven) bad = 1
      in_repositories = 0
    }
  }
  END { exit !(blocks == 2 && !bad) }
' "$ROOT_BUILD_FILE"; then
  printf '%s\n' "Traveller repositories must declare Google Maven before Maven Central in each repository block." >&2
  exit 1
fi

printf '%s\n' "Traveller Gradle dependency-resolution checks passed."
