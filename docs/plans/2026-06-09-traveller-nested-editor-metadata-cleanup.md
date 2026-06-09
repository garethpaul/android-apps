# Traveller Nested Editor Metadata Cleanup

## Status: Completed

## Context

The repository ignored IDE metadata and already had a baseline guard for root
workspace files, but the nested Traveller Android project still tracked files
under `traveller-android-app/.idea/`. Those files are machine/editor metadata
and can drift independently of app behavior.

## Objectives

- Remove tracked nested Android Studio metadata from the Traveller project.
- Keep the existing `.gitignore` editor metadata rules intact.
- Extend the SDK-free baseline to reject nested `.idea/` and `.vscode/` files.
- Preserve the legacy Gradle, Parse, and app source behavior.

## Work Completed

- Removed the tracked files under `traveller-android-app/.idea/`.
- Extended `scripts/check-baseline.sh` to scan nested editor metadata paths.
- Updated README, VISION, and CHANGES.

## Verification

- `scripts/check-baseline.sh`
- `make check`
- `git diff --check`
