# Enterprise Local CI/CD

Run the same quality gates as GitHub Actions (and more) on your laptop — **Linux or macOS**.

## One command

```bash
# Recommended before every PR / push
./tool/ci_local.sh
# or
make ci
```

## Profiles

| Profile | Command | What runs |
|---------|---------|-----------|
| **quick** | `./tool/ci_local.sh --profile quick` | doctor → deps → format → analyze → unit + coverage |
| **standard** (default) | `./tool/ci_local.sh` | + goldens → secret scan → SBOM/deps inventory |
| **full** | `./tool/ci_local.sh --profile full` | + integration (if device) → Android debug → web → iOS (macOS) |
| **release** | `./tool/ci_local.sh --profile release` | full + Android release APK/AAB |

```bash
make ci-quick
make ci
make ci-full
make ci-release
make ci-strict          # analyzer infos are fatal
```

## Flags / env

```bash
./tool/ci_local.sh --help

MIN_COVERAGE=50 ./tool/ci_local.sh
CI_STRICT=1 ./tool/ci_local.sh --strict
./tool/ci_local.sh --profile full --skip-integration
./tool/ci_local.sh --continue          # run all stages even if one fails
./tool/ci_local.sh --skip-build
```

## Prerequisites

| Tool | Linux | macOS |
|------|-------|-------|
| Flutter (stable) | required | required |
| bash | required | required (system bash is fine) |
| lcov | `sudo apt-get install -y lcov` | `brew install lcov` |
| Java 17 (for Android builds) | Temurin/OpenJDK | Temurin via brew |
| Xcode (iOS stages) | n/a | required for `build-ios` |
| Android SDK / emulator | optional for integration | optional |

## Artifacts

Each run writes:

```
.ci-artifacts/
  ci-report.md           # stage PASS/FAIL table
  flutter-version.txt
  flutter-doctor.txt
  pub-outdated.txt
  lcov.info
  coverage-html/         # if genhtml available
  deps.json / deps-compact.txt
  apk/  aab/             # when builds run
```

## Mapping to GitHub Actions

| Local stage | GitHub Actions job |
|-------------|--------------------|
| format + analyze | `Analyze` |
| unit-widget-coverage | `Unit & widget tests` |
| golden | `Golden tests` |
| build-android-debug | `Build Android APK (debug)` |
| build-android-release | `Build & Release` workflow |

Run `./tool/ci_local.sh` before opening a PR — if it passes locally, CI should pass remotely (same gates).

## Enterprise standard included here

1. Toolchain / doctor visibility  
2. Dependency resolve + outdated report  
3. Format gate  
4. Static analysis  
5. Automated tests + **coverage threshold**  
6. Visual regression (goldens)  
7. Secret hygiene scan  
8. Dependency inventory (lightweight SBOM)  
9. Compile verification (Android / optional iOS & web)  
10. Machine-readable report artifact  

## Recommended additions (when you need them)

- Wire `CI_STRICT=1` once `withOpacity` deprecations are cleaned up  
- Add Firestore emulator stage: `firebase emulators:exec --only firestore "./tool/ci_local.sh --profile full"`  
- Add Codecov upload from `.ci-artifacts/lcov.info` in GitHub Actions  
- Add Patrol/Maestro for richer mobile E2E  
- Add `syft`/`grype` for full SBOM + CVE scanning if compliance requires it  
