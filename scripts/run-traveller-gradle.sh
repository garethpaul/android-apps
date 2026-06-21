#!/usr/bin/env sh
set -eu

ROOT_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
PROJECT_DIR="$ROOT_DIR/traveller-android-app"
LINT_REPORT="$PROJECT_DIR/traveller/build/reports/lint-results.html"
LOG_FILE=$(mktemp "${TMPDIR:-/tmp}/traveller-gradle.XXXXXX")
trap 'rm -f "$LOG_FILE"' EXIT HUP INT TERM

rm -f "$PROJECT_DIR"/traveller/build/reports/lint-results.*

if ! (
  cd "$PROJECT_DIR"
  ./gradlew lint assembleDebug --no-daemon
) >"$LOG_FILE" 2>&1; then
  cat "$LOG_FILE" >&2
  exit 1
fi

cat "$LOG_FILE"

if grep -Fq "OutOfMemoryError" "$LOG_FILE"; then
  printf '%s\n' "Android lint reported an out-of-memory infrastructure failure." >&2
  exit 1
fi

if [ ! -s "$LINT_REPORT" ]; then
  printf '%s\n' "Android lint did not produce a nonempty lint-results.html report." >&2
  exit 1
fi
