## Android Apps Vision

Android Apps is a collection of personal Android app experiments. The current
checked-in project is the legacy Traveller app under `traveller-android-app/`.

The repository is useful as a preserved Android sample with an old Gradle stack,
Parse-era app structure, and explicit notes about local credential setup.
Project setup and verification details live in [`README.md`](README.md).

The goal is to keep the experiments recoverable and understandable while
protecting local credentials and making future modernization work deliberate.

The current focus is:

Priority:

- Preserve the Traveller project structure and documented legacy toolchain
- Keep Parse credentials out of git through `Constants.java.example`
- Maintain SDK-free baseline checks for quick verification
- Make old Gradle, Android plugin, and build-tools requirements explicit

Next priorities:

- Migrate Gradle, the Android Gradle Plugin, SDK levels, and dependencies in a
  dedicated modernization pass
- Replace Parse-era backend assumptions with documented alternatives if the app
  is revived
- Add Android tests once the project runs in an SDK-capable environment
- Separate reusable sample code from obsolete experiment scaffolding where it
  improves maintainability

Contribution rules:

- One PR = one focused experiment or maintenance topic.
- Run `scripts/check-baseline.sh` before pushing changes.
- When changing Android code, run the nested Gradle checks from
  `traveller-android-app/` with a compatible SDK.
- Keep real credentials, signing material, and local SDK paths untracked.

## Security And Privacy

Traveller uses local Parse credential configuration. Real credentials must stay
outside the repository, and examples should remain clearly non-secret.

Future network or account changes should document what user data is collected,
where it is sent, and how local developers configure it safely.

## What We Will Not Merge (For Now)

- Real Parse credentials, signing files, or local machine paths
- Broad AndroidX or Gradle migrations mixed with unrelated app behavior changes
- New backend dependencies without setup, privacy, and verification notes
- Changes that remove the existing baseline checks without replacing them

This list is a roadmap guardrail, not a permanent rule.
Strong user demand and strong technical rationale can change it.
