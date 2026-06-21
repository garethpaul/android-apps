#!/usr/bin/env sh
set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)

sha256_file() {
  file=$1

  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$file" | awk '{ print $1 }'
    return
  fi
  if command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "$file" | awk '{ print $1 }'
    return
  fi

  printf '%s\n' "Gradle wrapper authentication failed: no SHA-256 tool found." >&2
  exit 1
}

verify_digest() {
  expected=$1
  relative_path=$2
  file="$ROOT_DIR/$relative_path"

  if [ ! -f "$file" ]; then
    printf '%s\n' "Gradle wrapper authentication failed: missing $relative_path" >&2
    exit 1
  fi

  actual=$(sha256_file "$file")
  if [ "$actual" != "$expected" ]; then
    printf '%s\n' "Gradle wrapper authentication failed: $relative_path" >&2
    printf '%s\n' "expected $expected" >&2
    printf '%s\n' "actual   $actual" >&2
    exit 1
  fi
}

verify_digest "874d75d37bf38c810a8314e0b2f78a3c77fce9437963ae33cec8543d92662b61" \
  "traveller-android-app/gradlew"
verify_digest "e2b82129ab64751fd40437007bd2f7f2afb3c6e41a9198e628650b22d5824a14" \
  "traveller-android-app/gradle/wrapper/gradle-wrapper.jar"
verify_digest "3938dfe4bc3a01a40bd2da0c099bbc863381ec24e5cf5e3f4adb556fe2bf4621" \
  "traveller-android-app/gradle/wrapper/gradle-wrapper.properties"

printf '%s\n' "Traveller Gradle wrapper authentication checks passed."
