#!/usr/bin/env sh
set -eu

ROOT_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
WORKFLOW_FILE="$ROOT_DIR/.github/workflows/check.yml"
TEMP_ROOT=$(mktemp -d "${TMPDIR:-/tmp}/traveller-build-gate.XXXXXX")
trap 'rm -rf "$TEMP_ROOT"' EXIT HUP INT TERM

mkdir -p "$TEMP_ROOT/scripts"
mkdir -p "$TEMP_ROOT/traveller-android-app/traveller/src/main/java/com/requestlabs/traveller"
cp "$ROOT_DIR/Makefile" "$TEMP_ROOT/Makefile"
cp "$ROOT_DIR/scripts/prepare-traveller-constants.sh" "$TEMP_ROOT/scripts/"
cp "$ROOT_DIR/traveller-android-app/traveller/src/main/java/com/requestlabs/traveller/Constants.java.example" \
  "$TEMP_ROOT/traveller-android-app/traveller/src/main/java/com/requestlabs/traveller/"

cat > "$TEMP_ROOT/traveller-android-app/gradlew" <<'EOF'
#!/usr/bin/env sh
set -eu

if [ "$*" != "lint assembleDebug --no-daemon" ]; then
  printf '%s\n' "Unexpected Gradle arguments: $*" >&2
  exit 1
fi

sh ../scripts/prepare-traveller-constants.sh >/dev/null
printf '%s\n' "$*" > gradle-invocation.txt
EOF
chmod +x "$TEMP_ROOT/traveller-android-app/gradlew"

sdk_output=$(ANDROID_SDK_ROOT="$TEMP_ROOT/android-sdk" make -f "$TEMP_ROOT/Makefile" build 2>&1)
if printf '%s\n' "$sdk_output" | grep -Fq "Traveller Constants.java not configured; skipping Traveller Gradle build"; then
  printf '%s\n' "SDK-configured clean builds must invoke Gradle instead of skipping for missing Constants.java." >&2
  printf '%s\n' "$sdk_output" >&2
  exit 1
fi

if [ ! -f "$TEMP_ROOT/traveller-android-app/gradle-invocation.txt" ]; then
  printf '%s\n' "SDK-configured clean builds must invoke Gradle." >&2
  printf '%s\n' "$sdk_output" >&2
  exit 1
fi

cmp \
  "$TEMP_ROOT/traveller-android-app/traveller/src/main/java/com/requestlabs/traveller/Constants.java.example" \
  "$TEMP_ROOT/traveller-android-app/traveller/src/main/java/com/requestlabs/traveller/Constants.java"

if (
  unset ANDROID_HOME ANDROID_SDK_ROOT
  make -f "$TEMP_ROOT/Makefile" build >/dev/null 2>&1
); then
  printf '%s\n' "Build gate must fail closed when the Android SDK is not configured." >&2
  exit 1
fi

for sdk_package in 'platforms;android-19' 'build-tools;24.0.3'; do
  if ! grep -Fq "$sdk_package" "$WORKFLOW_FILE"; then
    printf '%s\n' "Hosted build gate must provision $sdk_package." >&2
    exit 1
  fi
done

if ! grep -Fq "ANDROID_SDK_ROOT=\$ANDROID_HOME" "$WORKFLOW_FILE"; then
  printf '%s\n' "Hosted build gate must export the configured Android SDK root." >&2
  exit 1
fi
if ! grep -Fq 'timeout-minutes: 15' "$WORKFLOW_FILE"; then
  printf '%s\n' "Hosted build gate must allow a bounded cold SDK and Gradle setup window." >&2
  exit 1
fi

printf '%s\n' "Traveller build gate clean-checkout checks passed."
