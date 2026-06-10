#!/usr/bin/env python3
from pathlib import Path
import re
import sys


ROOT = Path(__file__).resolve().parent.parent
WORKFLOW = ROOT / ".github" / "workflows" / "check.yml"
APP = ROOT / "traveller-android-app" / "traveller" / "src" / "main" / "java" / "com" / "requestlabs" / "traveller" / "App.java"
ACTIVITY = APP.with_name("MainActivity.java")
CHECKOUT_SHA = "df4cb1c069e1874edd31b4311f1884172cec0e10"


def fail(message):
    print(message, file=sys.stderr)
    raise SystemExit(1)


def uncommented_java(path):
    source = path.read_text()
    source = re.sub(
        r"\\u+([0-9a-fA-F]{4})",
        lambda match: chr(int(match.group(1), 16)),
        source,
    )
    source = re.sub(r"/\*.*?\*/", "", source, flags=re.S)
    return re.sub(r"//.*", "", source)


workflow = WORKFLOW.read_text()
workflow_code = "\n".join(line.split("#", 1)[0].rstrip() for line in workflow.splitlines())

required_patterns = {
    "pushes to master": r"(?m)^  push:\s*$\n    branches:\s*$\n      - master\s*$",
    "pull request trigger": r"(?m)^  pull_request:\s*$",
    "manual trigger": r"(?m)^  workflow_dispatch:\s*$",
    "read-only contents permission": r"(?m)^permissions:\s*$\n  contents: read\s*$",
    "fixed Ubuntu runner": r"(?m)^    runs-on: ubuntu-24\.04\s*$",
    "bounded timeout": r"(?m)^    timeout-minutes: 5\s*$",
    "credential-free checkout": r"(?m)^        with:\s*$\n          persist-credentials: false\s*$",
    "repository check": r"(?m)^        run: make check\s*$",
}
for description, pattern in required_patterns.items():
    if not re.search(pattern, workflow_code):
        fail(f"GitHub Actions workflow is missing {description}.")

if "pull_request_target:" in workflow_code:
    fail("GitHub Actions workflow must not use pull_request_target.")
if re.search(r"(?m)^\s*permissions:\s*write-all\s*$", workflow_code):
    fail("GitHub Actions workflow must not grant write-all permissions.")
if re.search(r"(?m)^    permissions:\s*", workflow_code):
    fail("GitHub Actions jobs must not override workflow permissions.")
if re.search(r"(?m)^\s+(?:actions|checks|contents|deployments|id-token|issues|packages|pull-requests|security-events|statuses): write\s*$", workflow_code):
    fail("GitHub Actions workflow must not grant write permissions.")

uses = re.findall(r"(?m)^\s*-?\s*uses:\s*([^\s]+)", workflow_code)
expected_checkout = f"actions/checkout@{CHECKOUT_SHA}"
if uses != [expected_checkout]:
    fail("GitHub Actions workflow must use only the approved immutable checkout action.")

app = uncommented_java(APP)
ordered = ["super.onCreate();", "configuredValue(Constants.api_key", "configuredValue(Constants.client_id", "Parse.initialize("]
positions = [app.find(item) for item in ordered]
if any(position < 0 for position in positions) or positions != sorted(positions):
    fail("Traveller startup must call super, normalize both credentials, then initialize Parse.")
if "return configuredValue;" not in app:
    fail("Traveller must initialize Parse with normalized credential values.")
if app.count("Constants.api_key") != 1 or app.count("Constants.client_id") != 1:
    fail("Traveller Parse credentials must only enter the configuration normalizer.")
if re.search(r"\b(?:Log\.|System\.out|System\.err)", app):
    fail("Traveller application startup must not write configuration to logs.")

activity = uncommented_java(ACTIVITY)
for contract in (
    "final int queryGeneration = mMutationGeneration;",
    "if(queryGeneration != mMutationGeneration)",
    "mMutationGeneration++;",
    "mPendingMutations++;",
    "mutationFinished();",
    "updateData(ParseQuery.CachePolicy.NETWORK_ONLY);",
):
    if contract not in activity:
        fail("Traveller task updates must guard asynchronous query callbacks.")
if "finish();" in activity or "startActivity(getIntent());" in activity:
    fail("Traveller task mutations must not restart the activity.")

print("Traveller automation contracts passed.")
