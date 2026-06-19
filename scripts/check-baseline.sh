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

require_exact_line() {
  file=$1
  pattern=$2
  message=$3

  if ! grep -Fxq "$pattern" "$ROOT_DIR/$file"; then
    printf '%s\n' "$message" >&2
    exit 1
  fi
}

for required_path in \
  "DEVICE_VERIFICATION.md" \
  "docs/plans/2026-06-14-traveller-device-verification-checklist.md"; do
  if [ ! -f "$ROOT_DIR/$required_path" ]; then
    printf '%s\n' "Required file is missing: $required_path" >&2
    exit 1
  fi
done

for device_contract in \
  'commit SHA and pull request' \
  'Placeholder constants' \
  'Cache miss then network' \
  'Repeated same-task saves' \
  'Stop during save' \
  'Process recreation' \
  'Do not convert `not run` into passing evidence.' \
  'Parse application IDs, client' \
  'every Android device and Parse backend row as' \
  'unexecuted'; do
  require_contains "DEVICE_VERIFICATION.md" "$device_contract" \
    "Traveller device checklist must keep contract: $device_contract"
done

require_contains "README.md" "DEVICE_VERIFICATION.md" \
  "README must link the Traveller device verification matrix."
require_contains "README.md" "explicit unexecuted rows" \
  "README must document the unexecuted device boundary."
require_contains "VISION.md" "Traveller device verification matrix" \
  "VISION must retain the device verification follow-up."
require_contains "CHANGES.md" "every runtime row explicitly unexecuted" \
  "CHANGES must record the unexecuted runtime matrix."

for plan_contract in \
  'Status: Completed' \
  'make check' \
  'hostile mutations' \
  'No Android SDK, emulator, physical-device, or live Parse scenario was executed'; do
  require_contains "docs/plans/2026-06-14-traveller-device-verification-checklist.md" \
    "$plan_contract" "Traveller device plan must keep completion evidence: $plan_contract"
done

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
  "task generateConstants(type: Exec)" \
  "Traveller Gradle build must define generateConstants."
require_contains "traveller-android-app/traveller/build.gradle" \
  "commandLine 'sh', new File(rootDir, '../scripts/prepare-traveller-constants.sh').canonicalPath" \
  "generateConstants must delegate to the idempotent repository helper."
require_contains "traveller-android-app/traveller/build.gradle" \
  "preBuild.dependsOn generateConstants" \
  "Traveller preBuild must generate missing local constants."
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

MANIFEST="traveller-android-app/traveller/src/main/AndroidManifest.xml"
exported_count=$(awk '
  {
    line = $0
    while (match(line, /android:exported=/)) {
      count++
      line = substr(line, RSTART + RLENGTH)
    }
  }
  END { print count + 0 }
' "$ROOT_DIR/$MANIFEST")
if [ "$exported_count" -ne 1 ]; then
  printf '%s\n' "Traveller must declare exactly one explicit component export boundary." >&2
  exit 1
fi
if ! awk '
  /<activity([[:space:]>]|$)/ {
    in_activity = 1
    name = 0
    exported = 0
    main_action = 0
    launcher_category = 0
  }
  in_activity && /android:name="com\.requestlabs\.traveller\.MainActivity"/ { name = 1 }
  in_activity && /android:exported="true"/ { exported++ }
  in_activity && /android.intent.action.MAIN/ { main_action = 1 }
  in_activity && /android.intent.category.LAUNCHER/ { launcher_category = 1 }
  in_activity && /<\/activity>/ {
    if (name && exported == 1 && main_action && launcher_category) {
      valid_launcher++
    }
    in_activity = 0
  }
  END { exit !(valid_launcher == 1) }
' "$ROOT_DIR/$MANIFEST"; then
  printf '%s\n' "Traveller launcher activity must be explicitly exported with its MAIN/LAUNCHER filter." >&2
  exit 1
fi
require_absent "$MANIFEST" 'android:exported="false"' \
  "Traveller launcher activity must remain externally reachable."

require_contains "traveller-android-app/traveller/src/main/java/com/requestlabs/traveller/App.java" \
  "requireParseConfiguration();" \
  "Traveller must validate local Parse configuration before initialization."
require_contains "traveller-android-app/traveller/src/main/java/com/requestlabs/traveller/App.java" \
  "super.onCreate();" \
  "Traveller Application startup must call the superclass lifecycle method."
if ! awk '
  /super\.onCreate\(\);/ { super_line = NR }
  /requireParseConfiguration\(\);/ && !guard_line { guard_line = NR }
  /Parse\.initialize\(/ { parse_line = NR }
  END { exit !(super_line && guard_line && parse_line && super_line < guard_line && guard_line < parse_line) }
' "$ROOT_DIR/traveller-android-app/traveller/src/main/java/com/requestlabs/traveller/App.java"; then
  printf '%s\n' "Traveller startup must call super, validate configuration, then initialize Parse." >&2
  exit 1
fi
require_contains "traveller-android-app/traveller/src/main/java/com/requestlabs/traveller/App.java" \
  'APPLICATION_ID_PLACEHOLDER = "parse-application-id"' \
  "Traveller must keep the Parse application-id placeholder explicit."
require_contains "traveller-android-app/traveller/src/main/java/com/requestlabs/traveller/App.java" \
  'CLIENT_KEY_PLACEHOLDER = "parse-client-key"' \
  "Traveller must keep the Parse client-key placeholder explicit."
require_contains "traveller-android-app/traveller/src/main/java/com/requestlabs/traveller/App.java" \
  "value.trim().length() > 0" \
  "Traveller must reject blank Parse configuration values."
require_contains "traveller-android-app/traveller/src/main/java/com/requestlabs/traveller/App.java" \
  '!placeholder.equals(value.trim())' \
  "Traveller must reject unchanged Parse placeholder values."
require_contains "traveller-android-app/traveller/src/main/java/com/requestlabs/traveller/App.java" \
  "Traveller Parse configuration is missing" \
  "Traveller must fail with a non-secret configuration diagnostic."
require_absent "traveller-android-app/traveller/src/main/java/com/requestlabs/traveller/App.java" \
  '" + Constants.' \
  "Traveller configuration diagnostics must not append Parse credential values."
require_absent "traveller-android-app/traveller/src/main/java/com/requestlabs/traveller/App.java" \
  'Constants.api_key +' \
  "Traveller configuration diagnostics must not prefix text with the Parse application id."
require_absent "traveller-android-app/traveller/src/main/java/com/requestlabs/traveller/App.java" \
  'Constants.client_id +' \
  "Traveller configuration diagnostics must not prefix text with the Parse client key."

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
  "TaskDescriptionNormalizer.normalize(null)" \
  "Traveller task description normalization must delegate missing input views to the pure normalizer."
require_contains "traveller-android-app/traveller/src/main/java/com/requestlabs/traveller/MainActivity.java" \
  "TaskDescriptionNormalizer.normalize(mTaskInput.getText().toString())" \
  "Traveller task descriptions must delegate entered text to the pure normalizer."
require_absent "traveller-android-app/traveller/src/main/java/com/requestlabs/traveller/MainActivity.java" \
  ".toString().trim()" \
  "Traveller task-description behavior must remain centralized in the pure normalizer."
if ! awk '
  /public void createTask\(View v\)/ { in_create = 1 }
  /private void saveNewTask\(final Item task\)/ { in_create = 0 }
  in_create && /if\(mTaskInput != null\)/ { clear_guard = NR }
  in_create && /mTaskInput\.setText\(""\);/ { clear_call = NR }
  END { exit !(clear_guard && clear_call && clear_guard < clear_call) }
' "$ROOT_DIR/traveller-android-app/traveller/src/main/java/com/requestlabs/traveller/MainActivity.java"; then
  printf '%s\n' "Traveller task creation must not clear a missing task input view." >&2
  exit 1
fi
for normalizer_contract in \
  "if(description == null)" \
  "while(start < end && isTaskWhitespace(description.charAt(start)))" \
  "while(start < end && isTaskWhitespace(description.charAt(end - 1)))" \
  "return description.substring(start, end);" \
  "private static boolean isTaskWhitespace(char value)" \
  "value <= ' '" \
  "Character.isWhitespace(value)" \
  "Character.isSpaceChar(value)"; do
  require_contains \
    "traveller-android-app/traveller/src/main/java/com/requestlabs/traveller/TaskDescriptionNormalizer.java" \
    "$normalizer_contract" \
    "Traveller task descriptions must keep boundary-whitespace contract: $normalizer_contract"
done
for normalizer_test_contract in \
  'assertNormalized("", null, "null descriptions")' \
  'assertNormalized("", "", "empty descriptions")' \
  'assertNormalized("", " \t\n ", "whitespace-only descriptions")' \
  'assertNormalized("", "\u00a0\u2003\u3000", "Unicode whitespace-only descriptions")' \
  'assertNormalized("Buy milk", "  Buy milk  ", "ASCII descriptions")' \
  'assertNormalized("café 東京", "  café 東京  ", "Unicode descriptions")' \
  'assertNormalized("café 東京", "\u00a0\u2003café 東京\u3000", "Unicode boundary whitespace")' \
  'assertNormalized("Plan\u00a0trip", "Plan\u00a0trip", "interior Unicode spacing")' \
  'assertNormalized("Buy milk", "\u0000Buy milk\u001f", "legacy trim control characters")'; do
  require_contains \
    "traveller-android-app/traveller/src/test/java/com/requestlabs/traveller/TaskDescriptionNormalizerTest.java" \
    "$normalizer_test_contract" \
    "Traveller task-description JVM test must keep case: $normalizer_test_contract"
done
require_contains "traveller-android-app/traveller/src/main/java/com/requestlabs/traveller/MainActivity.java" \
  "t.setDescription(description);" \
  "Traveller task creation must persist the normalized description."
require_absent "traveller-android-app/traveller/src/main/java/com/requestlabs/traveller/MainActivity.java" \
  "finish();" \
  "Traveller task mutations must not tear down the activity."
require_absent "traveller-android-app/traveller/src/main/java/com/requestlabs/traveller/MainActivity.java" \
  "startActivity(getIntent());" \
  "Traveller task mutations must not restart the activity."
require_contains "traveller-android-app/traveller/src/main/java/com/requestlabs/traveller/MainActivity.java" \
  "mAdapter.add(t);" \
  "Traveller task creation must update the current adapter in place."
require_contains "traveller-android-app/traveller/src/main/java/com/requestlabs/traveller/MainActivity.java" \
  "mAdapter.remove(task);" \
  "Traveller completed tasks must be removed from the current adapter in place."
require_absent "traveller-android-app/traveller/src/main/java/com/requestlabs/traveller/MainActivity.java" \
  "if(tasks != null)" \
  "Traveller task loading must not ignore Parse query errors."
require_contains "traveller-android-app/traveller/src/main/java/com/requestlabs/traveller/MainActivity.java" \
  "if(error == null && tasks != null)" \
  "Traveller task loading must only refresh on successful Parse results."
require_contains "traveller-android-app/traveller/src/main/java/com/requestlabs/traveller/MainActivity.java" \
  "R.string.load_items_error" \
  "Traveller task loading failures must use a localized error message."
require_contains "traveller-android-app/traveller/src/main/java/com/requestlabs/traveller/MainActivity.java" \
  "query.setCachePolicy(ParseQuery.CachePolicy.CACHE_THEN_NETWORK);" \
  "Traveller must retain cache-then-network task loading."
require_contains "traveller-android-app/traveller/src/main/java/com/requestlabs/traveller/MainActivity.java" \
  "error.getCode() != ParseException.CACHE_MISS" \
  "Traveller must suppress the expected intermediate cache-miss callback."
require_contains "traveller-android-app/traveller/src/main/java/com/requestlabs/traveller/MainActivity.java" \
  "private boolean deliveredTasks;" \
  "Traveller queries must track successful delivery inside each callback."
require_contains "traveller-android-app/traveller/src/main/java/com/requestlabs/traveller/MainActivity.java" \
  "deliveredTasks = true;" \
  "Traveller queries must record a successful task delivery."
require_contains "traveller-android-app/traveller/src/main/java/com/requestlabs/traveller/MainActivity.java" \
  "}else if(!deliveredTasks &&" \
  "Traveller must suppress later query errors after delivering tasks."
require_contains "traveller-android-app/traveller/src/main/java/com/requestlabs/traveller/MainActivity.java" \
  "(error == null || error.getCode() != ParseException.CACHE_MISS))" \
  "Traveller must keep first-delivery malformed results and non-cache failures visible."
if ! awk '
  /public void updateData\(\)/ { in_update = 1 }
  /public boolean onCreateOptionsMenu/ { in_update = 0 }
  in_update && /error.getCode\(\) != ParseException.CACHE_MISS/ { cache_guard = NR }
  in_update && /Toast\.makeText\(/ { toast = NR }
  END { exit !(cache_guard && toast && cache_guard < toast) }
' "$ROOT_DIR/traveller-android-app/traveller/src/main/java/com/requestlabs/traveller/MainActivity.java"; then
  printf '%s\n' "Traveller must suppress cache misses before displaying load errors." >&2
  exit 1
fi
if ! awk '
  /query\.findInBackground\(new FindCallback<Item>\(\)/ { in_callback = 1 }
  /public boolean onCreateOptionsMenu/ { in_callback = 0 }
  in_callback && /private boolean deliveredTasks;/ { declaration = NR }
  in_callback && /mAdapter\.addAll\(tasks\);/ { apply_tasks = NR }
  in_callback && /deliveredTasks = true;/ { delivered = NR }
  in_callback && /else if\(!deliveredTasks &&/ { error_guard = NR }
  in_callback && /Toast\.makeText\(/ { toast = NR }
  END {
    exit !(declaration && apply_tasks && delivered && error_guard && toast &&
      declaration < apply_tasks && apply_tasks < delivered &&
      delivered < error_guard && error_guard < toast)
  }
' "$ROOT_DIR/traveller-android-app/traveller/src/main/java/com/requestlabs/traveller/MainActivity.java"; then
  printf '%s\n' "Traveller must record callback-local delivery before suppressing later load errors." >&2
  exit 1
fi
for cache_miss_doc_contract in \
  "README.md|suppresses the expected cache-miss callback" \
  "SECURITY.md|Expected Parse cache misses do not display load-failure errors" \
  "VISION.md|Suppress expected cache-miss errors" \
  "CHANGES.md|Suppressed expected Parse cache-miss callbacks"; do
  cache_miss_doc=${cache_miss_doc_contract%%|*}
  cache_miss_text=${cache_miss_doc_contract#*|}
  require_contains "$cache_miss_doc" "$cache_miss_text" \
    "$cache_miss_doc must document cache-miss toast suppression."
done
require_contains "docs/plans/2026-06-14-traveller-cache-miss-toast-suppression.md" \
  "Status: Completed" \
  "Traveller cache-miss toast suppression plan must be completed."
require_contains "docs/plans/2026-06-14-traveller-cache-miss-toast-suppression.md" \
  "make check" \
  "Traveller cache-miss toast suppression plan must record make check."
require_contains "docs/plans/2026-06-14-traveller-cache-miss-toast-suppression.md" \
  "mutations" \
  "Traveller cache-miss toast suppression plan must record mutation evidence."
for cache_success_doc_contract in \
  "README.md|cached tasks remain visible without a later network-error toast" \
  "SECURITY.md|successful cached task delivery suppresses a later network-error toast" \
  "CHANGES.md|Suppressed later Parse network-error toasts after a successful cached task delivery"; do
  cache_success_doc=${cache_success_doc_contract%%|*}
  cache_success_text=${cache_success_doc_contract#*|}
  require_contains "$cache_success_doc" "$cache_success_text" \
    "$cache_success_doc must document cached-result error suppression."
done
for cache_success_plan_contract in \
  "Status: Completed" \
  "make check" \
  "hostile mutations" \
  "No emulator, physical-device, or live Parse scenario was executed"; do
  require_contains "docs/plans/2026-06-15-traveller-cache-success-error-suppression.md" \
    "$cache_success_plan_contract" \
    "Traveller cache-success error plan must keep completion evidence: $cache_success_plan_contract"
done
require_contains "traveller-android-app/traveller/src/main/java/com/requestlabs/traveller/MainActivity.java" \
  "private boolean mStarted;" \
  "Traveller must track whether MainActivity is started."
require_contains "traveller-android-app/traveller/src/main/java/com/requestlabs/traveller/MainActivity.java" \
  "private int mDataGeneration;" \
  "Traveller must track Parse query generations."
require_contains "traveller-android-app/traveller/src/main/java/com/requestlabs/traveller/MainActivity.java" \
  "final int dataGeneration = ++mDataGeneration;" \
  "Traveller refreshes must capture a new query generation."
generation_increment_count=$(grep -Eo '\+\+mDataGeneration|mDataGeneration\+\+' \
  "$ROOT_DIR/traveller-android-app/traveller/src/main/java/com/requestlabs/traveller/MainActivity.java" | wc -l | tr -d ' ')
if [ "$generation_increment_count" -ne 4 ]; then
  printf '%s\n' "Traveller must keep create, toggle, refresh, and stop generation invalidation." >&2
  exit 1
fi
if ! awk '
  /public void createTask\(View v\)/ { in_create = 1 }
  /private void saveNewTask\(final Item task\)/ { in_create = 0 }
  in_create && /mDataGeneration\+\+;/ { create_invalidate = NR }
  in_create && /mAdapter\.add\(t\);/ { create_add = NR }
  in_create && /saveNewTask\(t\);/ { create_save = NR }
  /public void onItemClick\(/ { in_toggle = 1 }
  /private void saveTaskCompletion\(/ { in_toggle = 0 }
  in_toggle && /mDataGeneration\+\+;/ { toggle_invalidate = NR }
  in_toggle && /task\.setCompleted\(!previousCompleted\);/ { toggle_mutate = NR }
  in_toggle && /saveTaskCompletion\(task, previousCompleted\);/ { toggle_save = NR }
  END {
    exit !(create_invalidate && create_add && create_save &&
      create_invalidate < create_add && create_add < create_save &&
      toggle_invalidate && toggle_mutate && toggle_save &&
      toggle_invalidate < toggle_mutate && toggle_mutate < toggle_save)
  }
' "$ROOT_DIR/traveller-android-app/traveller/src/main/java/com/requestlabs/traveller/MainActivity.java"; then
  printf '%s\n' "Traveller must invalidate stale queries before optimistic create and toggle mutations." >&2
  exit 1
fi
require_contains "traveller-android-app/traveller/src/main/java/com/requestlabs/traveller/MainActivity.java" \
  "if(!mStarted || dataGeneration != mDataGeneration || mAdapter == null)" \
  "Traveller callbacks must reject stopped, stale, or adapter-less results."
if ! awk '
  /protected void onStart\(\)/ { on_start = NR }
  /mStarted = true;/ { started = NR }
  /updateData\(\);/ { refresh = NR }
  /protected void onStop\(\)/ { on_stop = NR; in_stop = 1 }
  /mStarted = false;/ { stopped = NR }
  in_stop && /mDataGeneration\+\+;/ { invalidated = NR }
  /super\.onStop\(\);/ { super_stop = NR; in_stop = 0 }
  /if\(!mStarted \|\| dataGeneration != mDataGeneration \|\| mAdapter == null\)/ { guard = NR }
  /if\(error == null && tasks != null\)/ { apply_result = NR }
  /Toast\.makeText\(/ { toast = NR }
  END {
    exit !(on_start && started && refresh && on_start < started && started < refresh &&
      on_stop && stopped && invalidated && super_stop && on_stop < stopped &&
      stopped < invalidated && invalidated < super_stop && guard && apply_result &&
      toast && guard < apply_result && guard < toast)
  }
' "$ROOT_DIR/traveller-android-app/traveller/src/main/java/com/requestlabs/traveller/MainActivity.java"; then
  printf '%s\n' "Traveller lifecycle and stale-query guards must run before UI updates." >&2
  exit 1
fi
refresh_call_count=$(grep -Fc "updateData();" \
  "$ROOT_DIR/traveller-android-app/traveller/src/main/java/com/requestlabs/traveller/MainActivity.java")
if [ "$refresh_call_count" -ne 3 ]; then
  printf '%s\n' "Traveller must keep one lifecycle refresh and two save-failure refreshes." >&2
  exit 1
fi
if ! awk '
  /protected void onStart\(\)/ { in_start = 1 }
  /protected void onStop\(\)/ { in_start = 0 }
  in_start && /updateData\(\);/ { refreshes++ }
  END { exit !(refreshes == 1) }
' "$ROOT_DIR/traveller-android-app/traveller/src/main/java/com/requestlabs/traveller/MainActivity.java"; then
  printf '%s\n' "Traveller must start exactly one visible-lifecycle refresh path." >&2
  exit 1
fi
require_contains "traveller-android-app/traveller/src/main/res/values/strings.xml" \
  '<string name="load_items_error">Unable to load traveller items.</string>' \
  "Traveller task loading error string is missing."
require_contains "traveller-android-app/traveller/src/main/java/com/requestlabs/traveller/MainActivity.java" \
  "import com.parse.SaveCallback;" \
  "Traveller task saves must use the vendored Parse SaveCallback API."
save_callback_count=$(grep -Fc "saveEventually(new SaveCallback()" \
  "$ROOT_DIR/traveller-android-app/traveller/src/main/java/com/requestlabs/traveller/MainActivity.java")
if [ "$save_callback_count" -ne 2 ]; then
  printf '%s\n' "Traveller must attach exactly two callbacks to creation and toggle saves." >&2
  exit 1
fi
if ! awk '
  /mAdapter\.add\(t\);/ && !create_add { create_add = NR }
  /saveNewTask\(t\);/ { create_save = NR }
  /if\(task\.isCompleted\(\)\)/ && !toggle_branch { toggle_branch = NR }
  /saveTaskCompletion\(task, previousCompleted\);/ { toggle_save = NR }
  END {
    exit !(create_add && create_save && create_add < create_save &&
      toggle_branch && toggle_save && toggle_branch < toggle_save)
  }
' "$ROOT_DIR/traveller-android-app/traveller/src/main/java/com/requestlabs/traveller/MainActivity.java"; then
  printf '%s\n' "Traveller must update optimistic adapter state before queuing save callbacks." >&2
  exit 1
fi
for save_contract in \
  "saveNewTask(final Item task)" \
  "saveTaskCompletion(final Item task, final boolean previousCompleted)" \
  "if(error == null)" \
  "if(!mStarted || lifecycleGeneration != mLifecycleGeneration || mAdapter == null)" \
  "mAdapter.remove(task);" \
  "task.setCompleted(previousCompleted);" \
  "mAdapter.getPosition(task) < 0" \
  "mAdapter.notifyDataSetChanged();" \
  "showSaveFailure();" \
  "updateData();"; do
  require_contains "traveller-android-app/traveller/src/main/java/com/requestlabs/traveller/MainActivity.java" \
    "$save_contract" \
    "Traveller save failure reconciliation must keep contract: $save_contract"
done
lifecycle_capture_count=$(grep -Fc "final int lifecycleGeneration = mLifecycleGeneration;" \
  "$ROOT_DIR/traveller-android-app/traveller/src/main/java/com/requestlabs/traveller/MainActivity.java")
if [ "$lifecycle_capture_count" -ne 2 ]; then
  printf '%s\n' "Traveller must capture the lifecycle generation for both save callbacks." >&2
  exit 1
fi
save_lifecycle_guard_count=$(grep -Fc \
  "if(!mStarted || lifecycleGeneration != mLifecycleGeneration || mAdapter == null)" \
  "$ROOT_DIR/traveller-android-app/traveller/src/main/java/com/requestlabs/traveller/MainActivity.java")
if [ "$save_lifecycle_guard_count" -ne 2 ]; then
  printf '%s\n' "Traveller must reject both stale-lifecycle save callbacks." >&2
  exit 1
fi
lifecycle_increment_count=$(grep -Fc "mLifecycleGeneration++;" \
  "$ROOT_DIR/traveller-android-app/traveller/src/main/java/com/requestlabs/traveller/MainActivity.java")
if [ "$lifecycle_increment_count" -ne 2 ]; then
  printf '%s\n' "Traveller must advance lifecycle generation on start and stop." >&2
  exit 1
fi
require_contains "traveller-android-app/traveller/src/main/java/com/requestlabs/traveller/MainActivity.java" \
  "private int mLifecycleGeneration;" \
  "Traveller must track visible lifecycle generations independently."
if ! awk '
  /protected void onStart\(\)/ { in_start = 1 }
  /protected void onStop\(\)/ { in_start = 0; in_stop = 1 }
  /public void createTask\(View v\)/ { in_stop = 0 }
  in_start && /mStarted = true;/ { start_state = NR }
  in_start && /mLifecycleGeneration\+\+;/ { start_generation = NR }
  in_stop && /mStarted = false;/ { stop_state = NR }
  in_stop && /mLifecycleGeneration\+\+;/ { stop_generation = NR }
  END {
    exit !(start_state && start_generation && start_state < start_generation &&
      stop_state && stop_generation && stop_state < stop_generation)
  }
' "$ROOT_DIR/traveller-android-app/traveller/src/main/java/com/requestlabs/traveller/MainActivity.java"; then
  printf '%s\n' "Traveller must advance lifecycle generation after start and stop state changes." >&2
  exit 1
fi
if ! awk '
  /private void saveNewTask\(final Item task\)/ { in_create = 1 }
  /private String normalizedTaskDescription\(\)/ { in_create = 0 }
  in_create && /final int lifecycleGeneration = mLifecycleGeneration;/ { create_capture = NR }
  in_create && /task\.saveEventually\(new SaveCallback\(\)/ { create_save = NR }

  /private void saveTaskCompletion\(final Item task, final boolean previousCompleted\)/ { in_toggle = 1 }
  /private void showSaveFailure\(\)/ { in_toggle = 0 }
  in_toggle && /final int lifecycleGeneration = mLifecycleGeneration;/ { toggle_capture = NR }
  in_toggle && /task\.saveEventually\(new SaveCallback\(\)/ { toggle_save = NR }
  END {
    exit !(create_capture && create_save && create_capture < create_save &&
      toggle_capture && toggle_save && toggle_capture < toggle_save)
  }
' "$ROOT_DIR/traveller-android-app/traveller/src/main/java/com/requestlabs/traveller/MainActivity.java"; then
  printf '%s\n' "Traveller must capture lifecycle generations before queuing both saves." >&2
  exit 1
fi
if ! awk '
  /private void saveNewTask\(final Item task\)/ { in_create = 1 }
  /private String normalizedTaskDescription\(\)/ { in_create = 0 }
  in_create && /if\(error == null\)/ { create_error = NR }
  in_create && /lifecycleGeneration != mLifecycleGeneration/ { create_lifecycle = NR }
  in_create && /mAdapter\.remove\(task\);/ { create_remove = NR }
  in_create && /mAdapter\.notifyDataSetChanged\(\);/ { create_notify = NR }
  in_create && /showSaveFailure\(\);/ { create_toast = NR }
  in_create && /updateData\(\);/ { create_refresh = NR }

  /private void saveTaskCompletion\(final Item task, final boolean previousCompleted\)/ { in_toggle = 1 }
  /private void showSaveFailure\(\)/ { in_toggle = 0 }
  in_toggle && /if\(error == null\)/ { toggle_error = NR }
  in_toggle && /lifecycleGeneration != mLifecycleGeneration/ { toggle_lifecycle = NR }
  in_toggle && /task\.setCompleted\(previousCompleted\);/ { toggle_restore = NR }
  in_toggle && /if\(previousCompleted\)/ { toggle_branch = NR }
  in_toggle && /mAdapter\.remove\(task\);/ { toggle_remove = NR }
  in_toggle && /mAdapter\.getPosition\(task\) < 0/ { toggle_position = NR }
  in_toggle && /mAdapter\.notifyDataSetChanged\(\);/ { toggle_notify = NR }
  in_toggle && /showSaveFailure\(\);/ { toggle_toast = NR }
  in_toggle && /updateData\(\);/ { toggle_refresh = NR }
  END {
    create_ok = create_error && create_lifecycle && create_remove && create_notify &&
      create_toast && create_refresh && create_error < create_lifecycle &&
      create_lifecycle < create_remove && create_remove < create_notify &&
      create_notify < create_toast && create_toast < create_refresh
    toggle_ok = toggle_error && toggle_restore && toggle_lifecycle && toggle_branch && toggle_remove &&
      toggle_position && toggle_notify && toggle_toast && toggle_refresh &&
      toggle_error < toggle_lifecycle && toggle_lifecycle < toggle_restore &&
      toggle_restore < toggle_branch && toggle_branch < toggle_remove &&
      toggle_remove < toggle_position &&
      toggle_position < toggle_notify && toggle_notify < toggle_toast &&
      toggle_toast < toggle_refresh
    exit !(create_ok && toggle_ok)
  }
' "$ROOT_DIR/traveller-android-app/traveller/src/main/java/com/requestlabs/traveller/MainActivity.java"; then
  printf '%s\n' "Traveller save callbacks must guard, roll back, notify, report, and refresh in order." >&2
  exit 1
fi
for lifecycle_doc_contract in \
  "README.md|stale save callbacks from earlier visible lifecycles" \
  "SECURITY.md|stale save callbacks from earlier visible lifecycles" \
  "VISION.md|save callbacks from earlier visible lifecycles" \
  "CHANGES.md|stale save callbacks from earlier visible lifecycles"; do
  lifecycle_doc=${lifecycle_doc_contract%%|*}
  lifecycle_contract=${lifecycle_doc_contract#*|}
  require_contains "$lifecycle_doc" "$lifecycle_contract" \
    "$lifecycle_doc must document save callback lifecycle guards."
done
require_contains "docs/plans/2026-06-13-traveller-save-callback-lifecycle.md" \
  "Status: Completed" \
  "Traveller save callback lifecycle plan must be completed."
require_contains "docs/plans/2026-06-13-traveller-save-callback-lifecycle.md" \
  "hostile mutations" \
  "Traveller save callback lifecycle plan must record hostile mutations."
for task_save_contract in \
  "new IdentityHashMap<Item, Integer>()" \
  "final int saveGeneration = beginTaskSave(task);" \
  "if(!finishCurrentTaskSave(task, saveGeneration))" \
  "mSaveGenerations.clear();" \
  "mSaveGenerations.put(task, saveGeneration);" \
  "mSaveGenerations.remove(task);"; do
  require_contains "traveller-android-app/traveller/src/main/java/com/requestlabs/traveller/MainActivity.java" \
    "$task_save_contract" \
    "Traveller per-task save generations must keep contract: $task_save_contract"
done
task_save_capture_count=$(grep -Fc "final int saveGeneration = beginTaskSave(task);" \
  "$ROOT_DIR/traveller-android-app/traveller/src/main/java/com/requestlabs/traveller/MainActivity.java")
if [ "$task_save_capture_count" -ne 2 ]; then
  printf '%s\n' "Traveller must capture a per-task generation for both save paths." >&2
  exit 1
fi
task_save_guard_count=$(grep -Fc "if(!finishCurrentTaskSave(task, saveGeneration))" \
  "$ROOT_DIR/traveller-android-app/traveller/src/main/java/com/requestlabs/traveller/MainActivity.java")
if [ "$task_save_guard_count" -ne 2 ]; then
  printf '%s\n' "Traveller must reject stale same-item callbacks in both save paths." >&2
  exit 1
fi
if ! awk '
  /private void saveNewTask\(final Item task\)/ { in_create = 1 }
  /private String normalizedTaskDescription\(\)/ { in_create = 0 }
  in_create && /finishCurrentTaskSave\(task, saveGeneration\)/ { create_generation = NR }
  in_create && /if\(error == null\)/ { create_error = NR }

  /private void saveTaskCompletion\(final Item task, final boolean previousCompleted\)/ { in_toggle = 1 }
  /private int beginTaskSave\(Item task\)/ { in_toggle = 0 }
  in_toggle && /finishCurrentTaskSave\(task, saveGeneration\)/ { toggle_generation = NR }
  in_toggle && /if\(error == null\)/ { toggle_error = NR }
  END {
    exit !(create_generation && create_error && create_generation < create_error &&
      toggle_generation && toggle_error && toggle_generation < toggle_error)
  }
' "$ROOT_DIR/traveller-android-app/traveller/src/main/java/com/requestlabs/traveller/MainActivity.java"; then
  printf '%s\n' "Traveller must reject stale same-item callbacks before success or failure handling." >&2
  exit 1
fi
for task_save_doc_contract in \
  "README.md|latest save callback for each task identity" \
  "SECURITY.md|Per-task save generations reject older same-item callbacks" \
  "VISION.md|Reject older same-item save callbacks" \
  "CHANGES.md|per-task save generations"; do
  task_save_doc=${task_save_doc_contract%%|*}
  task_save_text=${task_save_doc_contract#*|}
  require_contains "$task_save_doc" "$task_save_text" \
    "$task_save_doc must document per-task save callback ownership."
done
require_contains "docs/plans/2026-06-14-traveller-per-task-save-generation.md" \
  "Status: Completed" \
  "Traveller per-task save generation plan must be completed."
require_contains "docs/plans/2026-06-14-traveller-per-task-save-generation.md" \
  "make check" \
  "Traveller per-task save generation plan must record make check."
require_contains "docs/plans/2026-06-14-traveller-per-task-save-generation.md" \
  "mutations" \
  "Traveller per-task save generation plan must record mutation evidence."
if awk '
  /private void saveNewTask\(final Item task\)/ { in_create = 1 }
  /private String normalizedTaskDescription\(\)/ { in_create = 0 }
  in_create && /dataGeneration != mDataGeneration/ { bad = 1 }

  /private void saveTaskCompletion\(final Item task, final boolean previousCompleted\)/ { in_toggle = 1 }
  /private int beginTaskSave\(Item task\)/ { in_toggle = 0 }
  in_toggle && /dataGeneration != mDataGeneration/ { bad = 1 }
  END { exit !bad }
' "$ROOT_DIR/traveller-android-app/traveller/src/main/java/com/requestlabs/traveller/MainActivity.java"; then
  printf '%s\n' "Traveller save failure reconciliation must not be suppressed by unrelated global data generations." >&2
  exit 1
fi
require_absent "traveller-android-app/traveller/src/main/java/com/requestlabs/traveller/MainActivity.java" \
  "final int dataGeneration = mDataGeneration;" \
  "Traveller save callbacks must not capture global data generations."
for save_data_doc_contract in \
  "README.md|same-task supersession is owned" \
  "SECURITY.md|Independent optimistic save failures still reconcile" \
  "VISION.md|Keep unrelated optimistic save failures independent" \
  "CHANGES.md|independent optimistic save failures"; do
  save_data_doc=${save_data_doc_contract%%|*}
  save_data_text=${save_data_doc_contract#*|}
  require_contains "$save_data_doc" "$save_data_text" \
    "$save_data_doc must document independent optimistic save failure ownership."
done
require_contains "docs/plans/2026-06-14-traveller-save-callback-data-generation.md" \
  "Status: Completed" \
  "Traveller save callback ownership plan must remain completed."
require_contains "docs/plans/2026-06-14-traveller-save-callback-data-generation.md" \
  "same-task supersession is owned" \
  "Traveller save callback ownership plan must record the corrected ownership boundary."
require_contains "docs/plans/2026-06-14-traveller-save-callback-data-generation.md" \
  "mutations" \
  "Traveller save callback ownership plan must record mutation evidence."
require_contains "traveller-android-app/traveller/src/main/res/values/strings.xml" \
  '<string name="save_item_error">Unable to save traveller item.</string>' \
  "Traveller task save failure string is missing."
require_contains "traveller-android-app/traveller/src/main/java/com/requestlabs/traveller/MainActivity.java" \
  "R.string.save_item_error" \
  "Traveller task save failures must use the localized generic resource."
for save_doc in "README.md" "SECURITY.md" "CHANGES.md"; do
  require_contains "$save_doc" \
    "optimistic task save failures" \
    "$save_doc must document optimistic task save failures."
done
require_contains "docs/plans/2026-06-13-traveller-save-failure-reconciliation.md" \
  "Status: Completed" \
  "Traveller save failure reconciliation plan must be completed."
require_contains "docs/plans/2026-06-13-traveller-save-failure-reconciliation.md" \
  "make check" \
  "Traveller save failure reconciliation plan must record make check."
require_contains "docs/plans/2026-06-13-traveller-save-failure-reconciliation.md" \
  "hostile mutations" \
  "Traveller save failure reconciliation plan must record hostile mutations."
require_contains "docs/plans/2026-06-13-traveller-optimistic-query-invalidation.md" \
  "Status: Completed" \
  "Traveller optimistic query invalidation plan must be completed."
require_contains "docs/plans/2026-06-13-traveller-optimistic-query-invalidation.md" \
  "make check" \
  "Traveller optimistic query invalidation plan must record make check."
require_contains "docs/plans/2026-06-13-traveller-optimistic-query-invalidation.md" \
  "hostile mutations" \
  "Traveller optimistic query invalidation plan must record hostile mutations."
for optimistic_doc in "README.md" "SECURITY.md" "VISION.md" "CHANGES.md"; do
  require_contains "$optimistic_doc" \
    "stale Parse query callbacks" \
    "$optimistic_doc must document optimistic stale-query invalidation."
done
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

APP_JAVA="traveller-android-app/traveller/src/main/java/com/requestlabs/traveller/App.java"
MAIN_ACTIVITY_JAVA="traveller-android-app/traveller/src/main/java/com/requestlabs/traveller/MainActivity.java"

register_count=$(grep -RFc "ParseObject.registerSubclass(Item.class)" \
  "$ROOT_DIR/traveller-android-app/traveller/src/main/java/com/requestlabs/traveller" \
  | awk -F: '{ total += $NF } END { print total + 0 }')
if [ "$register_count" -ne 1 ]; then
  printf '%s\n' "Item subclass registration should happen exactly once." >&2
  exit 1
fi

require_contains "$APP_JAVA" \
  "ParseObject.registerSubclass(Item.class);" \
  "Item subclass registration must be owned by the application bootstrap."
require_absent "$MAIN_ACTIVITY_JAVA" \
  "ParseObject.registerSubclass(Item.class);" \
  "MainActivity must not repeat process-wide Parse subclass registration."

register_line=$(grep -nF "ParseObject.registerSubclass(Item.class);" \
  "$ROOT_DIR/$APP_JAVA" | head -n 1 | cut -d: -f1)
initialize_line=$(grep -nF "Parse.initialize(" \
  "$ROOT_DIR/$APP_JAVA" | head -n 1 | cut -d: -f1)
if [ -z "$register_line" ] || [ -z "$initialize_line" ] || \
   [ "$register_line" -ge "$initialize_line" ]; then
  printf '%s\n' "Item subclass registration must precede Parse initialization." >&2
  exit 1
fi

for parse_registration_doc in "AGENTS.md" "README.md" "SECURITY.md" "VISION.md" "CHANGES.md"; do
  require_contains "$parse_registration_doc" \
    "application-owned Parse subclass registration" \
    "$parse_registration_doc must document Parse subclass bootstrap ownership."
done

for parse_registration_plan_contract in \
  "status: completed" \
  "make check" \
  "hostile mutations" \
  "No Android SDK, emulator, physical-device, or live Parse scenario was executed"; do
  require_contains "docs/plans/2026-06-15-traveller-parse-subclass-bootstrap.md" \
    "$parse_registration_plan_contract" \
    "Traveller Parse subclass bootstrap plan must keep completion evidence: $parse_registration_plan_contract"
done

for launcher_export_doc in "AGENTS.md" "README.md" "SECURITY.md" "VISION.md" "CHANGES.md"; do
  require_contains "$launcher_export_doc" "explicit launcher export boundary" \
    "$launcher_export_doc must document the explicit launcher export boundary."
done

for launcher_export_plan_contract in \
  "status: completed" \
  'android:exported="true"' \
  'repository and external-directory `make check` passed' \
  "hostile mutations were rejected"; do
  require_contains "docs/plans/2026-06-15-traveller-explicit-launcher-export.md" \
    "$launcher_export_plan_contract" \
    "Traveller launcher export plan must keep completion evidence: $launcher_export_plan_contract"
done

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
if [ ! -f "$ROOT_DIR/.github/workflows/check.yml" ]; then
  printf '%s\n' "GitHub Actions check workflow is missing." >&2
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
require_contains "Makefile" \
  '$(ROOT)scripts/test-task-description-normalizer.sh' \
  "Makefile test must run the dependency-free task-description JVM test."
for required_path in \
  "docs/plans/2026-06-16-traveller-task-description-jvm-test.md" \
  "docs/plans/2026-06-17-traveller-unicode-task-whitespace.md" \
  "scripts/test-task-description-normalizer.sh" \
  "traveller-android-app/traveller/src/main/java/com/requestlabs/traveller/TaskDescriptionNormalizer.java" \
  "traveller-android-app/traveller/src/test/java/com/requestlabs/traveller/TaskDescriptionNormalizerTest.java"; do
  if [ ! -f "$ROOT_DIR/$required_path" ]; then
    printf '%s\n' "Required task-description JVM test file is missing: $required_path" >&2
    exit 1
  fi
done
if [ ! -x "$ROOT_DIR/scripts/test-task-description-normalizer.sh" ]; then
  printf '%s\n' "Task-description JVM test runner must be executable." >&2
  exit 1
fi
for runner_contract in \
  'mktemp -d' \
  'trap '\''rm -rf "$BUILD_DIR"'\'' EXIT HUP INT TERM' \
  '"$JAVAC" -source 7 -target 7 -d "$BUILD_DIR"' \
  '"$JAVA" -cp "$BUILD_DIR" com.requestlabs.traveller.TaskDescriptionNormalizerTest'; do
  require_contains "scripts/test-task-description-normalizer.sh" "$runner_contract" \
    "Task-description JVM runner must keep contract: $runner_contract"
done
require_contains "docs/plans/2026-06-08-traveller-constants-helper.md" \
  "make check" \
  "Traveller constants helper plan must record make check verification."
require_contains ".github/workflows/check.yml" \
  "actions/checkout@df4cb1c069e1874edd31b4311f1884172cec0e10" \
  "GitHub Actions workflow must pin checkout to an immutable revision."
require_contains ".github/workflows/check.yml" \
  "persist-credentials: false" \
  "GitHub Actions checkout must not persist repository credentials."
require_contains ".github/workflows/check.yml" \
  "actions/setup-java@c5195efecf7bdfc987ee8bae7a71cb8b11521c00" \
  "GitHub Actions workflow must pin Java setup to an immutable revision."
require_contains ".github/workflows/check.yml" \
  "distribution: temurin" \
  "GitHub Actions workflow must select the Temurin JDK distribution."
require_contains ".github/workflows/check.yml" \
  "java-version: '8'" \
  "GitHub Actions workflow must run the legacy-compatible Java 8 test gate."
require_absent ".github/workflows/check.yml" \
  "branches:" \
  "GitHub Actions push checks must cover feature branches."
require_contains ".github/workflows/check.yml" \
  "permissions:" \
  "GitHub Actions workflow must declare permissions."
require_contains ".github/workflows/check.yml" \
  "contents: read" \
  "GitHub Actions workflow permissions must be read-only."
require_contains ".github/workflows/check.yml" \
  "timeout-minutes: 5" \
  "GitHub Actions workflow must have a bounded timeout."
require_contains ".github/workflows/check.yml" \
  "runs-on: ubuntu-24.04" \
  "GitHub Actions workflow must use a fixed Ubuntu runner image."
require_contains ".github/workflows/check.yml" \
  "cancel-in-progress: true" \
  "GitHub Actions workflow must cancel superseded runs."
require_contains ".github/workflows/check.yml" \
  "workflow_dispatch:" \
  "GitHub Actions workflow must support manual dispatch."
require_contains ".github/workflows/check.yml" \
  "make check" \
  "GitHub Actions workflow must run make check."
require_exact_line "Makefile" \
  'override ROOT := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))' \
  "Makefile must protect repository paths from command-line overrides."
require_exact_line "Makefile" \
  'TRAVELLER_CONSTANTS := $(ROOT)traveller-android-app/traveller/src/main/java/com/requestlabs/traveller/Constants.java' \
  "Makefile must derive Traveller constants from the protected repository root."
if [ "$(grep -Fc '$(ROOT)scripts/check-baseline.sh' "$ROOT_DIR/Makefile")" -ne 2 ]; then
  printf '%s\n' "Both baseline commands must use the protected repository root." >&2
  exit 1
fi
if [ "$(grep -Fc '$(ROOT)scripts/test-task-description-normalizer.sh' "$ROOT_DIR/Makefile")" -ne 1 ]; then
  printf '%s\n' "The JVM behavior test must use the protected repository root." >&2
  exit 1
fi
if [ "$(grep -Fc '$(ROOT)scripts/test-constants-generation.sh' "$ROOT_DIR/Makefile")" -ne 1 ]; then
  printf '%s\n' "The constants generation test must use the protected repository root." >&2
  exit 1
fi
if [ "$(grep -Fc '$(ROOT)scripts/prepare-traveller-constants.sh' "$ROOT_DIR/Makefile")" -ne 1 ]; then
  printf '%s\n' "The constants helper syntax check must use the protected repository root." >&2
  exit 1
fi
if [ "$(grep -Fc 'cd $(ROOT)traveller-android-app && ./gradlew lint assembleDebug --no-daemon' "$ROOT_DIR/Makefile")" -ne 1 ]; then
  printf '%s\n' "SDK-backed make build must run rooted Android lint before assembly." >&2
  exit 1
fi
require_exact_line "docs/plans/2026-06-14-traveller-make-root-override-protection.md" \
  "Status: Completed" \
  "Traveller Make root override protection plan must record completed status."

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
require_contains "README.md" "dependency-free JVM test" \
  "README must document the executable task-description behavior gate."
require_contains "README.md" "make build" \
  "README must document the make build gate."
require_contains "README.md" "GitHub Actions" \
  "README must document the GitHub Actions baseline."
require_contains "README.md" ".github/workflows/check.yml" \
  "README must document the GitHub Actions workflow path."
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
require_contains "docs/plans/2026-06-10-ci-baseline.md" \
  "Status: Completed" \
  "Traveller CI baseline plan must be completed."
require_contains "docs/plans/2026-06-10-ci-baseline.md" \
  "scripts/check-baseline.sh" \
  "Traveller CI baseline plan must document the active baseline checker."
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
require_contains "docs/plans/2026-06-10-traveller-in-place-task-updates.md" \
  "Status: Completed" \
  "Traveller in-place task update plan must be completed."
require_contains "docs/plans/2026-06-10-traveller-in-place-task-updates.md" \
  "make check" \
  "Traveller in-place task update plan must document make check verification."
require_contains "docs/plans/2026-06-12-traveller-query-lifecycle.md" \
  "Status: Completed" \
  "Traveller query lifecycle plan must be completed."
require_contains "docs/plans/2026-06-12-traveller-query-lifecycle.md" \
  "make check" \
  "Traveller query lifecycle plan must document make check verification."
require_contains "VISION.md" "GitHub Actions" \
  "VISION must document the GitHub Actions baseline."
require_contains "VISION.md" "make check" \
  "VISION must document the CI make check gate."
require_contains "CHANGES.md" "GitHub Actions" \
  "CHANGES must record the GitHub Actions baseline."
require_contains "CHANGES.md" "make check" \
  "CHANGES must record the CI make check gate."

for behavior_doc in "AGENTS.md" "README.md" "SECURITY.md" "VISION.md" "CHANGES.md"; do
  require_contains "$behavior_doc" "task-description behavior" \
    "$behavior_doc must document the portable task-description behavior gate."
done
for task_description_plan_contract in \
  "Status: Completed" \
  'Repository and external-directory `make test` and `make check` passed' \
  "hostile mutations were rejected" \
  "No Android SDK, emulator, physical-device, or live Parse scenario was executed"; do
  require_contains "docs/plans/2026-06-16-traveller-task-description-jvm-test.md" \
    "$task_description_plan_contract" \
    "Traveller task-description JVM test plan must keep completion evidence: $task_description_plan_contract"
done

unicode_whitespace_guidance="Traveller removes ASCII and Unicode boundary whitespace before rejecting empty task descriptions."
for unicode_whitespace_doc in "AGENTS.md" "README.md" "SECURITY.md" "VISION.md" "CHANGES.md"; do
  require_contains "$unicode_whitespace_doc" "$unicode_whitespace_guidance" \
    "$unicode_whitespace_doc must document Unicode task boundary whitespace."
done
for unicode_whitespace_plan_contract in \
  "Status: Completed" \
  'Repository and external-directory `make test` and `make check` passed' \
  "hostile mutations were rejected" \
  "No Android SDK, emulator, physical-device, or live Parse scenario was executed"; do
  require_contains "docs/plans/2026-06-17-traveller-unicode-task-whitespace.md" \
    "$unicode_whitespace_plan_contract" \
    "Traveller Unicode whitespace plan must keep completion evidence: $unicode_whitespace_plan_contract"
done

printf '%s\n' "Traveller Android baseline checks passed."
