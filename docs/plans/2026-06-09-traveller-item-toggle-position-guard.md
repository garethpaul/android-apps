# Traveller Item Toggle Position Guard

## Status: Completed

## Context

Traveller item toggles already guard missing adapters, selected items, row
views, and row text views before marking Parse-backed items complete. The click
handler still passed the raw adapter `position` into `mAdapter.getItem`, so a
stale or malformed list-click position could fail before the missing-item guard.

## Objectives

- Preserve existing item-toggle behavior for valid list positions.
- Return before adapter item lookup when `position` is negative.
- Return before adapter item lookup when `position` is outside adapter bounds.
- Cover the stale-position guard in the SDK-free baseline check.

## Work Completed

- Added an adapter position bounds check to `onItemClick`.
- Extended `scripts/check-baseline.sh` with the stale-position guard contract.
- Updated README, VISION, and CHANGES.

## Verification

- `scripts/check-baseline.sh`
- `make check`
- `git diff --check`
