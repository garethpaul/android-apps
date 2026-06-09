# Traveller Item Row Rendering Guards

Date: 2026-06-09
Status: Completed

## Problem

`ItemAdapter.getView` assumed every adapter position resolved through the
backing list, every row layout contained a `TextView` with the expected ID, and
every item description was non-null. Stale layouts or malformed local data could
crash row rendering before a user could recover.

## Scope

- Use the adapter item lookup instead of indexing the backing list directly.
- Return the row unchanged when the description view is missing or malformed.
- Render an empty description when the item or its description is missing.
- Preserve existing completed-item strike-through behavior.

## Verification

- Red: `make test` failed on the missing row-rendering baseline guard.
- Green: `make test` passes after adding the adapter guards.
- Full gate: `make check`.
