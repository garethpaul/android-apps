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
  'return "";' \
  "Traveller task description normalization must return an empty description for missing input views."
require_contains "traveller-android-app/traveller/src/main/java/com/requestlabs/traveller/MainActivity.java" \
  "return mTaskInput.getText().toString().trim();" \
  "Traveller task descriptions must be trimmed before validation."
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
require_contains "docs/plans/2026-06-08-traveller-constants-helper.md" \
  "make check" \
  "Traveller constants helper plan must record make check verification."
require_contains ".github/workflows/check.yml" \
  "actions/checkout@df4cb1c069e1874edd31b4311f1884172cec0e10" \
  "GitHub Actions workflow must pin checkout to an immutable revision."
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
require_contains "Makefile" \
  'ROOT := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))' \
  "Makefile must resolve repository paths from its own location."
require_contains "Makefile" \
  './gradlew lint assembleDebug --no-daemon' \
  "SDK-backed make build must run Android lint before assembling the debug APK."

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

printf '%s\n' "Traveller Android baseline checks passed."
