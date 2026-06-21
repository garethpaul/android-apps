# AGENTS.md

## Repository purpose

`garethpaul/android-apps` is an Android application or sample. Personal Android Apps

## Project structure

- `Makefile` - repository verification targets
- `scripts` - baseline checks and helper scripts
- `docs` - plans, notes, and generated README assets
- `traveller-android-app` - repository source or sample assets

## Development commands

- Install dependencies: no repository-specific install command is documented.
- Full baseline: `make check`
- Combined verification: `make verify`
- Lint/static checks: `make lint`
- Tests: `make test`
- Build: `make build`
- `make build` and `make check` fail closed when the Android SDK is unavailable; verify on a machine with that SDK before claiming platform behavior is tested.

## Coding conventions

- Language mix noted in the README: Java (4), shell (1).

## Testing guidance

- Keep `make test` executing the dependency-free build-gate, constants,
  Gradle/JDK toolchain, Gradle wrapper authentication, and portable
  task-description behavior tests without Android or Parse dependencies.
- Start with the narrowest relevant test or Make target, then run `make check` before handing off if the change is not documentation-only.
- Keep README verification notes in sync when commands, fixtures, or supported toolchains change.

## PR / change guidance

- Keep diffs focused on the requested repository and avoid unrelated modernization or formatting churn.
- Preserve public APIs, sample behavior, file formats, and documented environment variables unless the task explicitly changes them.
- Update tests, README notes, or docs/plans when behavior, security posture, or validation commands change.
- Call out skipped platform validation, legacy toolchain assumptions, and any risky files touched in the final summary.

## Safety and gotchas

- Detected references to Parse. Keep API keys, OAuth credentials, tokens, and account-specific values in local configuration only.
- Traveller is pinned to Android API 19, target SDK 19, build-tools 26.0.2, and
  AGP 3.0.1's legacy AAPT path for this legacy baseline.
- Gradle `preBuild` or `scripts/prepare-traveller-constants.sh` copies
  `Constants.java.example` only when the local file is missing. Replace the
  placeholder Parse values locally; `Constants.java` must stay ignored.
- Hosted CI authenticates the initially checked-out Gradle wrapper with an
  inline `/usr/bin/sha256sum` step immediately after checkout. Treat digest
  updates as security-sensitive; Make's local verifier mirrors the check but is
  not a security boundary for pull-request-authored repository code or
  caller-supplied post-auth wrapper replacement.
- Traveller trims task descriptions and rejects whitespace-only entries before saving Parse `Item` records.
- Traveller removes ASCII and Unicode boundary whitespace before rejecting empty task descriptions.
- Traveller treats a missing task input view as an empty description so stale layouts do not crash task creation.
- Traveller ignores item toggle events when the adapter, selected item, row view, or row text view is unavailable or malformed.
- Parse save callbacks must match the current visible lifecycle generation
  before adapter rollback, feedback, or refresh work.
- Keep application-owned Parse subclass registration ahead of SDK
  initialization; activities must not repeat process-wide model setup.
- Keep the explicit launcher export boundary on `MainActivity`, which owns the
  sole `MAIN`/`LAUNCHER` entry point; do not export unrelated components.

## Agent workflow

1. Inspect the README, Makefile, manifests, and the files directly related to the request.
2. Make the smallest source or docs change that satisfies the task; avoid generated, vendored, or local-environment files unless required.
3. Run the narrowest useful validation first, then `make check` or the documented package/platform gate when available.
4. If a required SDK, service credential, or external runtime is unavailable, record the skipped command and why.
5. Summarize changed files, commands run, and remaining risks or follow-up validation.
