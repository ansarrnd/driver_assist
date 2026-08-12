# Non-goals — do not copy as-is

This blueprint is a **product and architecture contract**, not a dump of the
Flutter project. When porting, deliberately leave behind:

## Framework APIs

- Flutter widgets, `BuildContext`, `Theme.of`, `MaterialApp`
- `dart:` libraries, pub package versions, `pubspec.yaml` structure
- BLoC boilerplate class names (keep the *pattern*: event → state → reduce)
- GetIt registration syntax
- Golden PNG bitmaps from `test/golden/`

## Build & tooling specifics

- Android Gradle / iOS CocoaPods layout
- Exact GitHub Actions Flutter version pins (re-pin for the new stack)
- `tool/ci_local.sh` shell that calls `flutter` (recreate equivalent)

## Temporary / placeholder assets

- Placeholder `firebase_options.dart` and sample `google-services.json`
- Any hardcoded demo API keys (replace with env / secrets manager)

## Product scope exclusions (current product)

Unless you explicitly expand the product:

- Multi-user auth and per-user ownership (schema sketch only)
- Maps / turn-by-turn navigation
- Payments or ticket booking integrations
- Live location sharing
- Backend Cloud Functions (client talks to Firestore directly today)

## Design anti-patterns to avoid when re-skinning

Per project frontend rules: do not default to purple gradients, cream+serif
terracotta kits, broadsheet layouts, or dashboard clutter in the first
viewport. Follow `design/screens.md` section jobs and `design/tokens.yaml`.

## What *must* stay equivalent

- Domain field names and `DriveType` values (`trip` | `ticket`)
- Alarm schedule-after-persist and cancel-on-delete rules
- Bootstrap order (prefs → load/seed → reschedule alarms → route)
- Acceptance scenarios in `qa/acceptance.feature`
- Storage key semantics for onboarding and theme
