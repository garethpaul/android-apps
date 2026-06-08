#!/usr/bin/env sh
set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)

require_contains() {
  file=$1
  pattern=$2
  message=$3

  if ! grep -Fq "$pattern" "$ROOT_DIR/$file"; then
    printf '%s\n' "$message" >&2
    exit 1
  fi
}

require_absent() {
  file=$1
  pattern=$2
  message=$3

  if grep -Fq "$pattern" "$ROOT_DIR/$file"; then
    printf '%s\n' "$message" >&2
    exit 1
  fi
}

require_contains "traveller-android-app/build.gradle" \
  "com.android.tools.build:gradle:0.8.3" \
  "Android Gradle Plugin must stay pinned to 0.8.3."
require_absent "traveller-android-app/build.gradle" \
  "com.android.tools.build:gradle:0.8.+" \
  "Android Gradle Plugin must not use a dynamic version."
require_contains "traveller-android-app/build.gradle" \
  "url 'https://repo1.maven.org/maven2'" \
  "Maven Central repositories must use HTTPS."

require_contains "traveller-android-app/traveller/build.gradle" \
  "buildToolsVersion \"24.0.3\"" \
  "Android build-tools must stay pinned to 24.0.3."
require_contains "traveller-android-app/traveller/build.gradle" \
  "com.android.support:appcompat-v7:19.1.0" \
  "appcompat must stay pinned to 19.1.0."
require_absent "traveller-android-app/traveller/build.gradle" \
  "appcompat-v7:+" \
  "appcompat must not use a dynamic version."
require_contains "traveller-android-app/traveller/build.gradle" \
  "task generateConstants" \
  "Traveller Gradle build must generate Constants.java from the template."
require_contains "traveller-android-app/traveller/build.gradle" \
  "Constants.java.example" \
  "Traveller Gradle build must reference Constants.java.example."
require_contains "traveller-android-app/traveller/build.gradle" \
  "preBuild.dependsOn generateConstants" \
  "Traveller preBuild must depend on Constants.java generation."

require_contains "traveller-android-app/gradle/wrapper/gradle-wrapper.properties" \
  "distributionUrl=https\\://services.gradle.org/distributions/gradle-1.10-all.zip" \
  "Gradle wrapper distribution must use HTTPS."
require_absent "traveller-android-app/gradle/wrapper/gradle-wrapper.properties" \
  "distributionUrl=http\\://services.gradle.org" \
  "Gradle wrapper distribution must not use HTTP."

if [ ! -x "$ROOT_DIR/traveller-android-app/gradlew" ]; then
  printf '%s\n' "Gradle wrapper must be executable." >&2
  exit 1
fi

if [ ! -f "$ROOT_DIR/traveller-android-app/traveller/src/main/java/com/requestlabs/traveller/Constants.java.example" ]; then
  printf '%s\n' "Parse credential template is missing." >&2
  exit 1
fi

if [ ! -f "$ROOT_DIR/CHANGES.md" ]; then
  printf '%s\n' "CHANGES.md is missing." >&2
  exit 1
fi

require_contains "traveller-android-app/traveller/lint.xml" \
  "GradleDependency" \
  "lint.xml must document the intentionally pinned legacy dependency baseline."
require_contains "traveller-android-app/traveller/lint.xml" \
  "LintError" \
  "lint.xml must document the obsolete lint API database limitation."

require_contains "README.md" "scripts/check-baseline.sh" \
  "README must document the SDK-free baseline check."
require_contains "README.md" "./gradlew lint --no-daemon" \
  "README must document Gradle lint verification."
require_contains "README.md" "./gradlew check --no-daemon" \
  "README must document Gradle check verification."
require_contains "README.md" "./gradlew assembleDebug --no-daemon" \
  "README must document Gradle build verification."
require_contains "README.md" "Android build-tools 24.0.3" \
  "README must document the pinned Android build-tools version."
require_contains "README.md" "Constants.java.example" \
  "README must document the Parse credential template."
require_contains "README.md" 'generates a placeholder `Constants.java`' \
  "README must document automatic placeholder Constants.java generation."

printf '%s\n' "Traveller Android baseline checks passed."
