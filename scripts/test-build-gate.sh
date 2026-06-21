#!/usr/bin/env sh
set -eu

ROOT_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
WORKFLOW_FILE="$ROOT_DIR/.github/workflows/check.yml"
TEMP_ROOT=$(mktemp -d "${TMPDIR:-/tmp}/traveller-build-gate.XXXXXX")
FAKE_JDK=$(mktemp -d "${TMPDIR:-/tmp}/traveller-build-fake-jdk.XXXXXX")
trap 'rm -rf "$TEMP_ROOT" "$FAKE_JDK"' EXIT HUP INT TERM

mkdir -p "$TEMP_ROOT/scripts"
mkdir -p "$TEMP_ROOT/traveller-android-app/gradle/wrapper"
mkdir -p "$TEMP_ROOT/traveller-android-app/traveller/src/main/java/com/requestlabs/traveller"
mkdir -p "$FAKE_JDK/bin"
cp "$ROOT_DIR/Makefile" "$TEMP_ROOT/Makefile"
cp "$ROOT_DIR/scripts/prepare-traveller-constants.sh" "$TEMP_ROOT/scripts/"
cp "$ROOT_DIR/scripts/run-traveller-gradle.sh" "$TEMP_ROOT/scripts/"
cp "$ROOT_DIR/scripts/verify-gradle-wrapper.sh" "$TEMP_ROOT/scripts/"
cp "$ROOT_DIR/traveller-android-app/gradlew" "$TEMP_ROOT/traveller-android-app/gradlew"
cp "$ROOT_DIR/traveller-android-app/gradle/wrapper/gradle-wrapper.jar" \
  "$TEMP_ROOT/traveller-android-app/gradle/wrapper/"
cp "$ROOT_DIR/traveller-android-app/gradle/wrapper/gradle-wrapper.properties" \
  "$TEMP_ROOT/traveller-android-app/gradle/wrapper/"
cp "$ROOT_DIR/traveller-android-app/traveller/src/main/java/com/requestlabs/traveller/Constants.java.example" \
  "$TEMP_ROOT/traveller-android-app/traveller/src/main/java/com/requestlabs/traveller/"

cat > "$FAKE_JDK/bin/java" <<'EOF'
#!/usr/bin/env sh
set -eu

found_main=0
for arg in "$@"; do
  if [ "$arg" = "org.gradle.wrapper.GradleWrapperMain" ]; then
    found_main=1
  fi
done
if [ "$found_main" -ne 1 ]; then
  printf '%s\n' "Gradle wrapper launcher did not invoke GradleWrapperMain." >&2
  exit 1
fi
case " $* " in
  *" org.gradle.wrapper.GradleWrapperMain lint assembleDebug --no-daemon "*) ;;
  *)
    printf '%s\n' "Unexpected Java-backed Gradle arguments: $*" >&2
    exit 1
    ;;
esac

if [ "${TRAVELLER_FAKE_LINT_OOM:-}" = "1" ]; then
  printf '%s\n' "java.lang.OutOfMemoryError: Java heap space" >&2
  exit 0
fi

if [ "${TRAVELLER_FAKE_LINT_INTERNAL_FAILURE:-}" = "1" ]; then
  mkdir -p traveller/build/reports
  printf '%s\n' '<html><body>partial lint report</body></html>' > traveller/build/reports/lint-results.html
  printf '%s\n' "Unexpected failure during lint analysis of null" >&2
  exit 0
fi

if [ "${TRAVELLER_FAKE_LINT_NO_REPORT:-}" = "1" ]; then
  printf '%s\n' "BUILD SUCCESSFUL without a lint report"
  exit 0
fi

sh ../scripts/prepare-traveller-constants.sh >/dev/null
mkdir -p traveller/build/reports
printf '%s\n' '<html><body>lint complete</body></html>' > traveller/build/reports/lint-results.html
printf '%s\n' "$*" > gradle-java-invocation.txt
printf '%s\n' "$0" > java-home-invocation.txt
case "$0" in
  */bin/java) ;;
  *)
    printf '%s\n' "Gradle wrapper did not use JAVA_HOME/bin/java: $0" >&2
    exit 1
    ;;
esac
EOF
cat > "$FAKE_JDK/bin/javac" <<'EOF'
#!/usr/bin/env sh
exit 0
EOF
chmod +x "$FAKE_JDK/bin/java" "$FAKE_JDK/bin/javac"
chmod +x "$TEMP_ROOT/traveller-android-app/gradlew"

sdk_output=$(JAVA_HOME="$FAKE_JDK" ANDROID_SDK_ROOT="$TEMP_ROOT/android-sdk" make -f "$TEMP_ROOT/Makefile" build 2>&1)
if printf '%s\n' "$sdk_output" | grep -Fq "Traveller Constants.java not configured; skipping Traveller Gradle build"; then
  printf '%s\n' "SDK-configured clean builds must invoke Gradle instead of skipping for missing Constants.java." >&2
  printf '%s\n' "$sdk_output" >&2
  exit 1
fi

if [ ! -f "$TEMP_ROOT/traveller-android-app/gradle-java-invocation.txt" ]; then
  printf '%s\n' "SDK-configured clean builds must invoke Gradle." >&2
  printf '%s\n' "$sdk_output" >&2
  exit 1
fi
if [ ! -f "$TEMP_ROOT/traveller-android-app/java-home-invocation.txt" ]; then
  printf '%s\n' "Hosted build-gate regression must prove gradlew uses JAVA_HOME/bin/java." >&2
  printf '%s\n' "$sdk_output" >&2
  exit 1
fi

if oom_output=$(TRAVELLER_FAKE_LINT_OOM=1 JAVA_HOME="$FAKE_JDK" ANDROID_SDK_ROOT="$TEMP_ROOT/android-sdk" make -f "$TEMP_ROOT/Makefile" build 2>&1); then
  printf '%s\n' "Build gate must fail closed when Android lint reports an out-of-memory failure." >&2
  printf '%s\n' "$oom_output" >&2
  exit 1
fi
if ! printf '%s\n' "$oom_output" | grep -Fq "OutOfMemoryError"; then
  printf '%s\n' "Build gate must preserve the Android lint infrastructure failure in its output." >&2
  printf '%s\n' "$oom_output" >&2
  exit 1
fi

if internal_output=$(TRAVELLER_FAKE_LINT_INTERNAL_FAILURE=1 JAVA_HOME="$FAKE_JDK" ANDROID_SDK_ROOT="$TEMP_ROOT/android-sdk" make -f "$TEMP_ROOT/Makefile" build 2>&1); then
  printf '%s\n' "Build gate must fail closed when Android lint reports an internal infrastructure failure." >&2
  printf '%s\n' "$internal_output" >&2
  exit 1
fi
if ! printf '%s\n' "$internal_output" | grep -Fq "Unexpected failure during lint analysis"; then
  printf '%s\n' "Build gate must preserve the Android lint internal failure in its output." >&2
  printf '%s\n' "$internal_output" >&2
  exit 1
fi

if missing_report_output=$(TRAVELLER_FAKE_LINT_NO_REPORT=1 JAVA_HOME="$FAKE_JDK" ANDROID_SDK_ROOT="$TEMP_ROOT/android-sdk" make -f "$TEMP_ROOT/Makefile" build 2>&1); then
  printf '%s\n' "Build gate must fail closed when Android lint produces no fresh report." >&2
  printf '%s\n' "$missing_report_output" >&2
  exit 1
fi
if ! printf '%s\n' "$missing_report_output" | grep -Fq "did not produce a nonempty lint-results.html report"; then
  printf '%s\n' "Build gate must report the missing fresh Android lint report." >&2
  printf '%s\n' "$missing_report_output" >&2
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

for sdk_package in 'platforms;android-19' 'build-tools;26.0.2'; do
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
