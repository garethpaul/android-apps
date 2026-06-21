#!/usr/bin/env sh
set -eu

if [ "${TRAVELLER_WRAPPER_AUTH_TEST_ACTIVE:-}" = "1" ]; then
  printf '%s\n' "Nested Traveller Gradle wrapper authentication mutation skipped."
  exit 0
fi

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
WORKFLOW_FILE="$ROOT_DIR/.github/workflows/check.yml"
LOCAL_VERIFIER="$ROOT_DIR/scripts/verify-gradle-wrapper.sh"
TEMP_ROOT=$(mktemp -d "${TMPDIR:-/tmp}/traveller-wrapper-auth.XXXXXX")
HOST_TOOLS=$(mktemp -d "${TMPDIR:-/tmp}/traveller-host-tools.XXXXXX")
trap 'rm -rf "$TEMP_ROOT" "$HOST_TOOLS"' EXIT HUP INT TERM

require_contains() {
  file=$1
  pattern=$2
  message=$3

  if ! grep -Fq "$pattern" "$file"; then
    printf '%s\n' "$message" >&2
    exit 1
  fi
}

line_number() {
  file=$1
  pattern=$2

  awk -v pattern="$pattern" 'index($0, pattern) { print NR; exit }' "$file"
}

require_order() {
  first_label=$1
  first_line=$2
  second_label=$3
  second_line=$4

  if [ -z "$first_line" ] || [ -z "$second_line" ] || [ "$first_line" -ge "$second_line" ]; then
    printf '%s\n' "Workflow must run $first_label before $second_label." >&2
    exit 1
  fi
}

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

  printf '%s\n' "No local SHA-256 tool available for workflow manifest simulation." >&2
  exit 1
}

extract_workflow_manifest() {
  workflow_file=$1
  output_file=$2
  start_marker="/usr/bin/sha256sum --strict --check <<'GRADLE_WRAPPER_SHA256'"

  awk -v start_marker="$start_marker" '
    index($0, start_marker) {
      in_manifest = 1
      next
    }
    in_manifest && index($0, "GRADLE_WRAPPER_SHA256") {
      exit
    }
    in_manifest {
      line = $0
      sub(/^[[:space:]]*/, "", line)
      print line
    }
  ' "$workflow_file" > "$output_file"

  if [ ! -s "$output_file" ]; then
    printf '%s\n' "Workflow Gradle wrapper digest manifest is missing." >&2
    exit 1
  fi
}

validate_manifest() {
  root=$1
  manifest=$2

  while IFS= read -r line; do
    [ -n "$line" ] || continue
    expected=${line%%  *}
    relative_path=${line#*  }
    if [ "$expected" = "$line" ] || [ -z "$relative_path" ]; then
      printf '%s\n' "Workflow Gradle wrapper authentication failed: malformed digest line $line" >&2
      return 1
    fi
    if [ ! -f "$root/$relative_path" ]; then
      printf '%s\n' "Workflow Gradle wrapper authentication failed: missing $relative_path" >&2
      return 1
    fi
    actual=$(sha256_file "$root/$relative_path")
    if [ "$actual" != "$expected" ]; then
      printf '%s\n' "Workflow Gradle wrapper authentication failed: $relative_path" >&2
      printf '%s\n' "expected $expected" >&2
      printf '%s\n' "actual   $actual" >&2
      return 1
    fi
  done < "$manifest"
}

for digest_line in \
  "cf139290d3b7334cc99b58ecb6adc549c59ecb8f1f4162b122ad4590ead7585e  traveller-android-app/gradlew" \
  "f4d953f31fbf6c38a8c330d19171c8ba6e0d1ff59d4d5c5c2d3ed821c9f3d5a3  traveller-android-app/gradle/wrapper/gradle-wrapper.jar" \
  "45971c7481b5fb9a3bc7345986390cf518d1d47803af4a0007e9201e4167c38c  traveller-android-app/gradle/wrapper/gradle-wrapper.properties"; do
  require_contains "$WORKFLOW_FILE" "$digest_line" \
    "Workflow must inline reviewed Gradle wrapper digest: $digest_line"
  digest=${digest_line%%  *}
  path=${digest_line#*  }
  require_contains "$LOCAL_VERIFIER" "$digest" \
    "Local Gradle wrapper verifier must mirror digest $digest."
  require_contains "$LOCAL_VERIFIER" "$path" \
    "Local Gradle wrapper verifier must mirror path $path."
done

require_contains "$WORKFLOW_FILE" "name: Authenticate Gradle wrapper" \
  "Workflow must authenticate the Gradle wrapper before running repository code."
require_contains "$WORKFLOW_FILE" "test -x /usr/bin/sha256sum" \
  "Workflow must require the Ubuntu system sha256sum command."
require_contains "$WORKFLOW_FILE" "/usr/bin/sha256sum --strict --check <<'GRADLE_WRAPPER_SHA256'" \
  "Workflow must use absolute system sha256sum for wrapper authentication."

checkout_line=$(line_number "$WORKFLOW_FILE" "name: Check out repository")
auth_line=$(line_number "$WORKFLOW_FILE" "name: Authenticate Gradle wrapper")
sdk_line=$(line_number "$WORKFLOW_FILE" "name: Provision legacy Android SDK")
java_line=$(line_number "$WORKFLOW_FILE" "name: Set up Java")
make_line=$(line_number "$WORKFLOW_FILE" "name: Run Traveller baseline")
require_order "repository checkout" "$checkout_line" "Gradle wrapper authentication" "$auth_line"
require_order "Gradle wrapper authentication" "$auth_line" "Android SDK provisioning" "$sdk_line"
require_order "Gradle wrapper authentication" "$auth_line" "Java setup" "$java_line"
require_order "Gradle wrapper authentication" "$auth_line" "make check" "$make_line"

if awk -v start="$checkout_line" -v end="$auth_line" '
  NR > start && NR < end && /^[[:space:]]+- name:/ { found = 1 }
  END { exit found ? 0 : 1 }
' "$WORKFLOW_FILE"; then
  printf '%s\n' "Gradle wrapper authentication must be the first post-checkout workflow step." >&2
  exit 1
fi

if awk -v start="$checkout_line" -v end="$auth_line" '
  NR > start && NR < end && (index($0, "run:") || index($0, "scripts/") || index($0, "make check") || index($0, "setup-java") || index($0, "sdkmanager")) { found = 1 }
  END { exit found ? 0 : 1 }
' "$WORKFLOW_FILE"; then
  printf '%s\n' "No setup, SDK, Make, or repository script may run before wrapper authentication." >&2
  exit 1
fi

tar -C "$ROOT_DIR" -cf - . | tar -C "$TEMP_ROOT" -xf -
WORKFLOW_MANIFEST="$TEMP_ROOT/workflow-gradle-wrapper.sha256"
extract_workflow_manifest "$TEMP_ROOT/.github/workflows/check.yml" "$WORKFLOW_MANIFEST"

cat > "$HOST_TOOLS/javac" <<'EOF'
#!/usr/bin/env sh
exit 0
EOF
cat > "$HOST_TOOLS/java" <<'EOF'
#!/usr/bin/env sh
exit 0
EOF
chmod +x "$HOST_TOOLS/javac" "$HOST_TOOLS/java"

ORIGINAL_GRADLEW="$TEMP_ROOT/original-gradlew"
cp "$TEMP_ROOT/traveller-android-app/gradlew" "$ORIGINAL_GRADLEW"

cat > "$TEMP_ROOT/traveller-android-app/gradlew" <<'EOF'
#!/usr/bin/env sh
printf '%s\n' "FAKE_GRADLEW_EXECUTED" >&2
touch fake-gradlew-executed
exit 0
EOF
chmod +x "$TEMP_ROOT/traveller-android-app/gradlew"

cat > "$TEMP_ROOT/scripts/verify-gradle-wrapper.sh" <<EOF
#!/usr/bin/env sh
touch "$TEMP_ROOT/local-verifier-laundered"
cp "$ORIGINAL_GRADLEW" "$TEMP_ROOT/traveller-android-app/gradlew"
exit 0
EOF
chmod +x "$TEMP_ROOT/scripts/verify-gradle-wrapper.sh"

if validate_manifest "$TEMP_ROOT" "$WORKFLOW_MANIFEST" >/dev/null 2>&1; then
  printf '%s\n' "Workflow inline authentication must reject a replaced Gradle wrapper launcher." >&2
  exit 1
fi
if [ -f "$TEMP_ROOT/traveller-android-app/fake-gradlew-executed" ]; then
  printf '%s\n' "Workflow inline authentication must reject the fake launcher before execution." >&2
  exit 1
fi
if [ -f "$TEMP_ROOT/local-verifier-laundered" ]; then
  printf '%s\n' "Workflow inline authentication must not run a laundered repository verifier." >&2
  exit 1
fi
if cmp -s "$ORIGINAL_GRADLEW" "$TEMP_ROOT/traveller-android-app/gradlew"; then
  printf '%s\n' "Workflow inline authentication must reject before self-restoring repository code can launder the fake launcher." >&2
  exit 1
fi

cp "$ROOT_DIR/scripts/verify-gradle-wrapper.sh" "$TEMP_ROOT/scripts/verify-gradle-wrapper.sh"
chmod +x "$TEMP_ROOT/scripts/verify-gradle-wrapper.sh"

CHECK_STDOUT="$TEMP_ROOT/make-check.stdout"
CHECK_STDERR="$TEMP_ROOT/make-check.stderr"
set +e
(
  cd "$TEMP_ROOT"
  PATH="$HOST_TOOLS:$PATH" \
  JAVAC=javac \
  JAVA=java \
  ANDROID_SDK_ROOT="$TEMP_ROOT/android-sdk" \
  TRAVELLER_WRAPPER_AUTH_TEST_ACTIVE=1 \
  make check
) >"$CHECK_STDOUT" 2>"$CHECK_STDERR"
check_status=$?
set -e

if [ "$check_status" -eq 0 ] && [ -f "$TEMP_ROOT/traveller-android-app/fake-gradlew-executed" ]; then
  printf '%s\n' "Hosted-equivalent make check returned 0 after executing a replaced Gradle wrapper launcher." >&2
  cat "$CHECK_STDOUT" >&2
  cat "$CHECK_STDERR" >&2
  exit 1
fi

if [ "$check_status" -eq 0 ]; then
  printf '%s\n' "Hosted-equivalent make check must reject a replaced Gradle wrapper launcher." >&2
  cat "$CHECK_STDOUT" >&2
  cat "$CHECK_STDERR" >&2
  exit 1
fi

if [ -f "$TEMP_ROOT/traveller-android-app/fake-gradlew-executed" ]; then
  printf '%s\n' "Gradle wrapper authentication must reject the fake launcher before execution." >&2
  cat "$CHECK_STDOUT" >&2
  cat "$CHECK_STDERR" >&2
  exit 1
fi

if ! cat "$CHECK_STDOUT" "$CHECK_STDERR" | grep -Fq "Gradle wrapper authentication failed"; then
  printf '%s\n' "Fake Gradle wrapper rejection must use the authentication diagnostic." >&2
  cat "$CHECK_STDOUT" >&2
  cat "$CHECK_STDERR" >&2
  exit 1
fi

mv "$ORIGINAL_GRADLEW" "$TEMP_ROOT/traveller-android-app/gradlew"
chmod +x "$TEMP_ROOT/traveller-android-app/gradlew"

"$TEMP_ROOT/scripts/verify-gradle-wrapper.sh" >/dev/null
validate_manifest "$TEMP_ROOT" "$WORKFLOW_MANIFEST" >/dev/null

POST_AUTH_GRADLEW="$TEMP_ROOT/post-auth-gradlew"
cp "$TEMP_ROOT/traveller-android-app/gradlew" "$POST_AUTH_GRADLEW"
cat > "$TEMP_ROOT/traveller-android-app/gradlew" <<'EOF'
#!/usr/bin/env sh
printf '%s\n' "POST_AUTH_FAKE_GRADLEW_EXECUTED" >&2
touch post-auth-fake-gradlew-executed
exit 0
EOF
chmod +x "$TEMP_ROOT/traveller-android-app/gradlew"

if "$TEMP_ROOT/scripts/verify-gradle-wrapper.sh" >/dev/null 2>&1; then
  printf '%s\n' "Local verifier must reject caller-supplied post-auth Gradle wrapper replacement." >&2
  exit 1
fi
if [ -f "$TEMP_ROOT/traveller-android-app/post-auth-fake-gradlew-executed" ]; then
  printf '%s\n' "Local post-auth verifier must reject replacement before Gradle execution." >&2
  exit 1
fi
mv "$POST_AUTH_GRADLEW" "$TEMP_ROOT/traveller-android-app/gradlew"
chmod +x "$TEMP_ROOT/traveller-android-app/gradlew"
"$TEMP_ROOT/scripts/verify-gradle-wrapper.sh" >/dev/null

for wrapper_path in \
  "traveller-android-app/gradlew" \
  "traveller-android-app/gradle/wrapper/gradle-wrapper.jar" \
  "traveller-android-app/gradle/wrapper/gradle-wrapper.properties"; do
  backup_path="$TEMP_ROOT/$wrapper_path.saved"
  cp "$TEMP_ROOT/$wrapper_path" "$backup_path"
  printf '%s\n' "wrapper-authentication-mutation" >> "$TEMP_ROOT/$wrapper_path"

  if validate_manifest "$TEMP_ROOT" "$WORKFLOW_MANIFEST" >/dev/null 2>&1; then
    printf '%s\n' "Workflow inline authentication must reject mutated $wrapper_path." >&2
    exit 1
  fi
  if "$TEMP_ROOT/scripts/verify-gradle-wrapper.sh" >/dev/null 2>&1; then
    printf '%s\n' "Local Gradle wrapper verifier must reject mutated $wrapper_path." >&2
    exit 1
  fi

  mv "$backup_path" "$TEMP_ROOT/$wrapper_path"
  "$TEMP_ROOT/scripts/verify-gradle-wrapper.sh" >/dev/null
  validate_manifest "$TEMP_ROOT" "$WORKFLOW_MANIFEST" >/dev/null
done

printf '%s\n' "Traveller Gradle wrapper authentication mutation checks passed."
