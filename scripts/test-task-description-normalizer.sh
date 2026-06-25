#!/usr/bin/env sh
set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
JAVAC=${JAVAC:-javac}
JAVA=${JAVA:-java}

if ! command -v "$JAVAC" >/dev/null 2>&1; then
  printf '%s\n' "Java compiler not found: $JAVAC" >&2
  exit 1
fi
if ! command -v "$JAVA" >/dev/null 2>&1; then
  printf '%s\n' "Java runtime not found: $JAVA" >&2
  exit 1
fi

BUILD_DIR=$(mktemp -d "${TMPDIR:-/tmp}/traveller-task-description.XXXXXX")
trap 'rm -rf "$BUILD_DIR"' EXIT HUP INT TERM

"$JAVAC" -source 7 -target 7 -encoding UTF-8 -d "$BUILD_DIR" \
  "$ROOT_DIR/traveller-android-app/traveller/src/main/java/com/requestlabs/traveller/TaskDescriptionNormalizer.java" \
  "$ROOT_DIR/traveller-android-app/traveller/src/test/java/com/requestlabs/traveller/TaskDescriptionNormalizerTest.java"
"$JAVA" -cp "$BUILD_DIR" com.requestlabs.traveller.TaskDescriptionNormalizerTest

rm -rf "$BUILD_DIR"
trap - EXIT HUP INT TERM
printf '%s\n' "Traveller task-description JVM test passed."
