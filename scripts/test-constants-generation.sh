#!/usr/bin/env sh
set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
BUILD_FILE="$ROOT_DIR/traveller-android-app/traveller/build.gradle"

require_build_contract() {
  pattern=$1
  message=$2

  if ! grep -Fq "$pattern" "$BUILD_FILE"; then
    printf '%s\n' "$message" >&2
    exit 1
  fi
}

require_build_contract "task generateConstants(type: Exec)" \
  "Traveller Gradle build must define generateConstants."
require_build_contract "commandLine 'sh', new File(rootDir, '../scripts/prepare-traveller-constants.sh').canonicalPath" \
  "generateConstants must delegate to the idempotent repository helper."
require_build_contract "preBuild.dependsOn generateConstants" \
  "Traveller preBuild must generate missing local constants."

TEMP_ROOT=$(mktemp -d "${TMPDIR:-/tmp}/traveller-constants-test.XXXXXX")
trap 'rm -rf "$TEMP_ROOT"' EXIT HUP INT TERM

mkdir -p "$TEMP_ROOT/scripts"
mkdir -p "$TEMP_ROOT/traveller-android-app/traveller/src/main/java/com/requestlabs/traveller"
cp "$ROOT_DIR/scripts/prepare-traveller-constants.sh" "$TEMP_ROOT/scripts/"
cp "$ROOT_DIR/traveller-android-app/traveller/src/main/java/com/requestlabs/traveller/Constants.java.example" \
  "$TEMP_ROOT/traveller-android-app/traveller/src/main/java/com/requestlabs/traveller/"

sh "$TEMP_ROOT/scripts/prepare-traveller-constants.sh" >/dev/null
cmp \
  "$TEMP_ROOT/traveller-android-app/traveller/src/main/java/com/requestlabs/traveller/Constants.java.example" \
  "$TEMP_ROOT/traveller-android-app/traveller/src/main/java/com/requestlabs/traveller/Constants.java"

printf '%s\n' 'local-secret-sentinel' > \
  "$TEMP_ROOT/traveller-android-app/traveller/src/main/java/com/requestlabs/traveller/Constants.java"
sh "$TEMP_ROOT/scripts/prepare-traveller-constants.sh" >/dev/null

if [ "$(cat "$TEMP_ROOT/traveller-android-app/traveller/src/main/java/com/requestlabs/traveller/Constants.java")" != \
  'local-secret-sentinel' ]; then
  printf '%s\n' "Constants generation must not overwrite local credentials." >&2
  exit 1
fi

printf '%s\n' "Traveller constants generation checks passed."
