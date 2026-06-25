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

verify_digest "cf139290d3b7334cc99b58ecb6adc549c59ecb8f1f4162b122ad4590ead7585e" \
  "traveller-android-app/gradlew"
verify_digest "f4d953f31fbf6c38a8c330d19171c8ba6e0d1ff59d4d5c5c2d3ed821c9f3d5a3" \
  "traveller-android-app/gradle/wrapper/gradle-wrapper.jar"
verify_digest "45971c7481b5fb9a3bc7345986390cf518d1d47803af4a0007e9201e4167c38c" \
  "traveller-android-app/gradle/wrapper/gradle-wrapper.properties"

printf '%s\n' "Traveller Gradle wrapper authentication checks passed."
