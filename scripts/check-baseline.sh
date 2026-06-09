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

require_contains "traveller-android-app/gradle/wrapper/gradle-wrapper.properties" \
  "distributionUrl=https\\://services.gradle.org/distributions/gradle-1.10-all.zip" \
  "Gradle wrapper distribution must use HTTPS."
require_absent "traveller-android-app/gradle/wrapper/gradle-wrapper.properties" \
  "distributionUrl=http\\://services.gradle.org" \
  "Gradle wrapper distribution must not use HTTP."

require_contains "traveller-android-app/traveller/src/main/AndroidManifest.xml" \
  'android:allowBackup="false"' \
  "Traveller must disable Android backups for local Parse state."
require_absent "traveller-android-app/traveller/src/main/AndroidManifest.xml" \
  'android:allowBackup="true"' \
  "Traveller must not allow Android backups."

if [ ! -x "$ROOT_DIR/traveller-android-app/gradlew" ]; then
  printf '%s\n' "Gradle wrapper must be executable." >&2
  exit 1
fi

if [ ! -f "$ROOT_DIR/traveller-android-app/traveller/src/main/java/com/requestlabs/traveller/Constants.java.example" ]; then
  printf '%s\n' "Parse credential template is missing." >&2
  exit 1
fi

if [ ! -x "$ROOT_DIR/scripts/prepare-traveller-constants.sh" ]; then
  printf '%s\n' "Traveller constants preparation helper is missing or not executable." >&2
  exit 1
fi

require_absent "traveller-android-app/traveller/src/main/java/com/requestlabs/traveller/ItemAdapter.java" \
  "inflate(R.layout.item_row_item, null)" \
  "ItemAdapter must inflate rows with parent layout params."
require_contains "traveller-android-app/traveller/src/main/java/com/requestlabs/traveller/ItemAdapter.java" \
  "inflate(R.layout.item_row_item, parent, false)" \
  "ItemAdapter must pass the parent with attachToRoot=false."

require_absent "traveller-android-app/traveller/src/main/java/com/requestlabs/traveller/MainActivity.java" \
  "mTaskInput.getText().length()" \
  "Traveller task creation must not validate raw EditText length."
require_contains "traveller-android-app/traveller/src/main/java/com/requestlabs/traveller/MainActivity.java" \
  "normalizedTaskDescription()" \
  "Traveller task creation must use a normalized task description helper."
require_contains "traveller-android-app/traveller/src/main/java/com/requestlabs/traveller/MainActivity.java" \
  "if(mTaskInput == null || mTaskInput.getText() == null)" \
  "Traveller task description normalization must tolerate missing input views."
require_contains "traveller-android-app/traveller/src/main/java/com/requestlabs/traveller/MainActivity.java" \
  'return "";' \
  "Traveller task description normalization must return an empty description for missing input views."
require_contains "traveller-android-app/traveller/src/main/java/com/requestlabs/traveller/MainActivity.java" \
  "return mTaskInput.getText().toString().trim();" \
  "Traveller task descriptions must be trimmed before validation."
require_contains "traveller-android-app/traveller/src/main/java/com/requestlabs/traveller/MainActivity.java" \
  "t.setDescription(description);" \
  "Traveller task creation must persist the normalized description."
require_absent "traveller-android-app/traveller/src/main/java/com/requestlabs/traveller/MainActivity.java" \
  "if(tasks != null)" \
  "Traveller task loading must not ignore Parse query errors."
require_contains "traveller-android-app/traveller/src/main/java/com/requestlabs/traveller/MainActivity.java" \
  "if(error == null && tasks != null)" \
  "Traveller task loading must only refresh on successful Parse results."
require_contains "traveller-android-app/traveller/src/main/java/com/requestlabs/traveller/MainActivity.java" \
  "R.string.load_items_error" \
  "Traveller task loading failures must use a localized error message."
require_contains "traveller-android-app/traveller/src/main/res/values/strings.xml" \
  '<string name="load_items_error">Unable to load traveller items.</string>' \
  "Traveller task loading error string is missing."
require_contains "traveller-android-app/traveller/src/main/java/com/requestlabs/traveller/MainActivity.java" \
  "if(mAdapter == null)" \
  "Traveller item toggles must guard missing adapters."
require_contains "traveller-android-app/traveller/src/main/java/com/requestlabs/traveller/MainActivity.java" \
  "if(position < 0 || position >= mAdapter.getCount())" \
  "Traveller item toggles must guard stale adapter positions."
require_contains "traveller-android-app/traveller/src/main/java/com/requestlabs/traveller/MainActivity.java" \
  "if(task == null)" \
  "Traveller item toggles must guard missing task items."
require_contains "traveller-android-app/traveller/src/main/java/com/requestlabs/traveller/MainActivity.java" \
  "if(view == null)" \
  "Traveller item toggles must guard missing row views."
require_contains "traveller-android-app/traveller/src/main/java/com/requestlabs/traveller/MainActivity.java" \
  "taskDescriptionView instanceof TextView" \
  "Traveller item toggles must guard malformed row text views."
require_contains "traveller-android-app/traveller/src/main/java/com/requestlabs/traveller/MainActivity.java" \
  "if(taskDescription == null)" \
  "Traveller item toggles must guard missing row text views."
require_absent "traveller-android-app/traveller/src/main/java/com/requestlabs/traveller/ItemAdapter.java" \
  "mTasks.get(position)" \
  "Traveller item rows must not assume backing-list positions are always valid."
require_contains "traveller-android-app/traveller/src/main/java/com/requestlabs/traveller/ItemAdapter.java" \
  "getItem(position)" \
  "Traveller item rows must use the adapter item lookup."
require_contains "traveller-android-app/traveller/src/main/java/com/requestlabs/traveller/ItemAdapter.java" \
  "descriptionViewCandidate instanceof TextView" \
  "Traveller item rows must guard malformed description views."
require_contains "traveller-android-app/traveller/src/main/java/com/requestlabs/traveller/ItemAdapter.java" \
  "if(task == null)" \
  "Traveller item rows must guard missing task items."
require_contains "traveller-android-app/traveller/src/main/java/com/requestlabs/traveller/ItemAdapter.java" \
  "if(description == null)" \
  "Traveller item rows must guard missing task descriptions."

register_count=$(grep -Fc "ParseObject.registerSubclass(Item.class)" \
  "$ROOT_DIR/traveller-android-app/traveller/src/main/java/com/requestlabs/traveller/MainActivity.java")
if [ "$register_count" -ne 1 ]; then
  printf '%s\n' "Item subclass registration should happen exactly once." >&2
  exit 1
fi

require_contains "traveller-android-app/.gitignore" \
  "Constants.java" \
  "Generated Constants.java must stay ignored."
require_contains ".gitignore" \
  "*.iml" \
  "IntelliJ module files must stay ignored."
require_contains ".gitignore" \
  ".idea/" \
  "IntelliJ workspace metadata must stay ignored."
require_contains ".gitignore" \
  ".vscode/" \
  "VS Code workspace metadata must stay ignored."

tracked_editor_files=$(git -C "$ROOT_DIR" ls-files -- \
  '*.iml' \
  '.idea' \
  '.idea/**' \
  '*/.idea' \
  '*/.idea/**' \
  '.vscode' \
  '.vscode/**' \
  '*/.vscode' \
  '*/.vscode/**')
if [ -n "$tracked_editor_files" ]; then
  printf '%s\n' "IDE metadata must not be tracked: $tracked_editor_files" >&2
  exit 1
fi

if [ ! -f "$ROOT_DIR/CHANGES.md" ]; then
  printf '%s\n' "CHANGES.md is missing." >&2
  exit 1
fi

require_contains "Makefile" \
  "scripts/check-baseline.sh" \
  "Makefile must expose the SDK-free baseline check."
require_contains "Makefile" \
  "lint:" \
  "Makefile must expose a lint gate."
require_contains "Makefile" \
  "test:" \
  "Makefile must expose a test gate."
require_contains "Makefile" \
  "build:" \
  "Makefile must expose a build gate."
require_contains "Makefile" \
  "verify: lint test build" \
  "Makefile verify must run lint, test, and build gates in order."
require_contains "docs/plans/2026-06-08-traveller-constants-helper.md" \
  "make check" \
  "Traveller constants helper plan must record make check verification."

require_contains "traveller-android-app/traveller/lint.xml" \
  "GradleDependency" \
  "lint.xml must document the intentionally pinned legacy dependency baseline."
require_contains "traveller-android-app/traveller/lint.xml" \
  "LintError" \
  "lint.xml must document the obsolete lint API database limitation."

require_contains "README.md" "scripts/check-baseline.sh" \
  "README must document the SDK-free baseline check."
require_contains "README.md" "make check" \
  "README must document the make check wrapper."
require_contains "README.md" "make lint" \
  "README must document the make lint gate."
require_contains "README.md" "make test" \
  "README must document the make test gate."
require_contains "README.md" "make build" \
  "README must document the make build gate."
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
require_contains "README.md" "scripts/prepare-traveller-constants.sh" \
  "README must document the constants preparation helper."
require_contains "docs/plans/2026-06-09-traveller-make-gate-targets.md" \
  "make lint" \
  "Traveller Make gate plan must document make lint verification."
require_contains "docs/plans/2026-06-09-traveller-task-input-null-guard.md" \
  "make check" \
  "Traveller task input null guard plan must document make check verification."
require_contains "docs/plans/2026-06-09-traveller-editor-metadata-ignore.md" \
  "Status: Completed" \
  "Traveller editor metadata ignore plan must be completed."
require_contains "docs/plans/2026-06-09-traveller-editor-metadata-ignore.md" \
  "make check" \
  "Traveller editor metadata ignore plan must document make check verification."
require_contains "docs/plans/2026-06-09-traveller-nested-editor-metadata-cleanup.md" \
  "Status: Completed" \
  "Traveller nested editor metadata cleanup plan must be completed."
require_contains "docs/plans/2026-06-09-traveller-nested-editor-metadata-cleanup.md" \
  "make check" \
  "Traveller nested editor metadata cleanup plan must document make check verification."
require_contains "docs/plans/2026-06-09-traveller-item-row-rendering-guards.md" \
  "Status: Completed" \
  "Traveller item row rendering guard plan must be completed."
require_contains "docs/plans/2026-06-09-traveller-item-row-rendering-guards.md" \
  "make check" \
  "Traveller item row rendering guard plan must document make check verification."
require_contains "docs/plans/2026-06-09-traveller-item-toggle-position-guard.md" \
  "Status: Completed" \
  "Traveller item toggle position guard plan must be completed."
require_contains "docs/plans/2026-06-09-traveller-item-toggle-position-guard.md" \
  "make check" \
  "Traveller item toggle position guard plan must document make check verification."

printf '%s\n' "Traveller Android baseline checks passed."
