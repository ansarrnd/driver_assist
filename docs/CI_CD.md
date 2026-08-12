# CI / CD

This project uses GitHub Actions for continuous integration and release builds.

## Workflows

| Workflow | Trigger | What it does |
|----------|---------|--------------|
| [`.github/workflows/ci.yml`](../.github/workflows/ci.yml) | PR / push to `main` | Format, analyze, unit/widget tests + coverage gate, goldens, debug APK |
| [`.github/workflows/build-release.yml`](../.github/workflows/build-release.yml) | Tag `v*` or manual | Release APK/AAB + GitHub Release |
| [`.github/dependabot.yml`](../.github/dependabot.yml) | Weekly / monthly | Dependency update PRs |

## Local equivalents

```bash
# Enterprise local runner (Linux + macOS) — preferred
./tool/ci_local.sh
make ci

# Or individual steps
dart format --output=none --set-exit-if-changed lib test integration_test tool
flutter analyze --no-fatal-infos
bash tool/check_coverage.sh
flutter test test/goldens
flutter build apk --debug
```

Full guide: [LOCAL_CI.md](LOCAL_CI.md).

## Required / optional secrets

| Secret | Required for | Purpose |
|--------|--------------|---------|
| `ANDROID_KEYSTORE_BASE64` | Signed Play Store builds | Base64-encoded `.jks` / `.keystore` |
| `ANDROID_KEY_ALIAS` | Signed builds | Key alias |
| `ANDROID_KEY_PASSWORD` | Signed builds | Key password |
| `ANDROID_STORE_PASSWORD` | Signed builds | Keystore password |

Without those secrets, release builds fall back to **debug signing** (fine for CI artifacts, not for Play Store).

## Recommended inclusions (not yet wired)

### High value next

1. **Integration tests on emulator** — `reactivecircus/android-emulator-runner` + `flutter test integration_test`
2. **Codecov / Coveralls** — publish `coverage/lcov.info` and fail PRs on coverage drop
3. **PR status checks as required** — protect `main` so Analyze + Unit & widget + Golden must pass
4. **Real Firebase options in CI** — inject `google-services.json` / `firebase_options.dart` from secrets or use the Firestore emulator job
5. **Firestore emulator job** — start emulator, set `FIRESTORE_EMULATOR_HOST`, run repository/integration tests

### Platform builds

6. **iOS build (macOS runner)** — `flutter build ipa` / `ios --no-codesign` for compile verification
7. **Web build** — `flutter build web` if you ship a web target
8. **Fastlane / supply** — upload AAB to Play Console internal track on tag
9. **TestFlight upload** — after iOS signing is configured

### Quality & security

10. **`very_good_analysis` or stricter lints** — then enable `--fatal-infos`
11. **`dart fix --apply` bot** / auto-format PR comment
12. **CodeQL / dependency review** — GitHub security scanning for Actions + Dart deps
13. **Secret scanning** — ensure keystores and Firebase keys never land in git
14. **License / SBOM generation** — useful for compliance

### Product / ops

15. **Firebase App Distribution** — push debug/release APKs to testers on every `main` push
16. **Slack / Discord notifications** — build failure alerts
17. **Changelog automation** — `release-please` or conventional commits → release notes
18. **Matrix Flutter channels** — occasional `beta`/`master` smoke to catch upcoming breaks
19. **Patrol / Maestro** — richer mobile UI automation beyond `integration_test`
20. **Screenshot / golden CI on macOS** — more stable pixel baselines than Linux for some renderers

## Branch protection (recommended)

In GitHub → Settings → Branches → Protect `main`:

- Require PR before merge
- Require status checks:
  - `Analyze`
  - `Unit & widget tests`
  - `Golden tests`
- Require conversation resolution
- Do not allow force pushes

## Tagging a release

```bash
git tag v1.1.0
git push origin v1.1.0
```

That triggers the Build & Release workflow and creates a GitHub Release with APK/AAB artifacts when available.
