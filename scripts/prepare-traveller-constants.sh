#!/usr/bin/env sh
set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
CONSTANTS_DIR="$ROOT_DIR/traveller-android-app/traveller/src/main/java/com/requestlabs/traveller"
TEMPLATE="$CONSTANTS_DIR/Constants.java.example"
TARGET="$CONSTANTS_DIR/Constants.java"

if [ ! -f "$TEMPLATE" ]; then
  printf '%s\n' "Missing constants template: $TEMPLATE" >&2
  exit 1
fi

if [ -f "$TARGET" ]; then
  printf '%s\n' "Traveller constants already exist at $TARGET"
  exit 0
fi

cp "$TEMPLATE" "$TARGET"
printf '%s\n' "Created $TARGET from Constants.java.example"
printf '%s\n' "Replace placeholder Parse values locally; do not commit Constants.java."
