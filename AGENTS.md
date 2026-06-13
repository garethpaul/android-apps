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
- If a command above skips because a platform toolchain is missing, verify on a machine with that SDK before claiming platform behavior is tested.

## Coding conventions

- Language mix noted in the README: Java (4), shell (1).

## Testing guidance

- No dedicated test files were detected; treat `make check` as the minimum baseline.
- Start with the narrowest relevant test or Make target, then run `make check` before handing off if the change is not documentation-only.
- Keep README verification notes in sync when commands, fixtures, or supported toolchains change.

## PR / change guidance

- Keep diffs focused on the requested repository and avoid unrelated modernization or formatting churn.
- Preserve public APIs, sample behavior, file formats, and documented environment variables unless the task explicitly changes them.
- Update tests, README notes, or docs/plans when behavior, security posture, or validation commands change.
- Call out skipped platform validation, legacy toolchain assumptions, and any risky files touched in the final summary.

## Safety and gotchas

- Detected references to Parse. Keep API keys, OAuth credentials, tokens, and account-specific values in local configuration only.
- Traveller is pinned to Android build-tools 24.0.3 for this legacy baseline.
- Copy `Constants.java.example` with `scripts/prepare-traveller-constants.sh`, then replace placeholder Parse values locally. `Constants.java` must stay ignored.
- Traveller trims task descriptions and rejects whitespace-only entries before saving Parse `Item` records.
- Traveller treats a missing task input view as an empty description so stale layouts do not crash task creation.
- Traveller ignores item toggle events when the adapter, selected item, row view, or row text view is unavailable or malformed.
- Parse save callbacks must match the current visible lifecycle generation
  before adapter rollback, feedback, or refresh work.

## Agent workflow

1. Inspect the README, Makefile, manifests, and the files directly related to the request.
2. Make the smallest source or docs change that satisfies the task; avoid generated, vendored, or local-environment files unless required.
3. Run the narrowest useful validation first, then `make check` or the documented package/platform gate when available.
4. If a required SDK, service credential, or external runtime is unavailable, record the skipped command and why.
5. Summarize changed files, commands run, and remaining risks or follow-up validation.
