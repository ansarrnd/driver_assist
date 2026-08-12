# QA & coverage gates

Portable quality bar derived from the reference project.

## Test layers

| Layer | Purpose | Reference location |
|-------|---------|-------------------|
| Unit | Entities, use cases, pure filters, BLoC logic | `test/domain/`, `test/features/` |
| Widget | Screen composition with fakes | `test/features/**/*_test.dart` |
| Golden | Visual regression for themes & key screens | `test/golden/` |
| Integration | End-to-end flows with fake or emulator backend | `integration_test/` |
| Coverage gate | Minimum line coverage on `lib/` | `tool/check_coverage.sh` |

## Minimum gates (enterprise local / CI)

| Gate | Command shape | Pass criteria |
|------|---------------|---------------|
| Format | `dart format --set-exit-if-changed .` | No diffs |
| Analyze | `flutter analyze --no-fatal-infos` | No errors |
| Unit+widget | `flutter test --coverage` | All pass |
| Coverage | `tool/check_coverage.sh` | Default **≥ 35%** (raise per team) |
| Goldens | `flutter test --tags=golden` | Pixel match (update consciously) |
| Integration | `flutter test integration_test` | All scenarios pass |
| Debug APK | `flutter build apk --debug` | Builds |

Local orchestration: `tool/ci_local.sh` profiles `quick` | `standard` | `full` | `release`.

## Acceptance mapping

Gherkin in `acceptance.feature` maps to:

- Onboarding → integration onboarding flow
- Filter / add / edit / delete → schedule + form widget & integration tests
- Themes → ThemeBloc unit + golden theme pack suite
- Alarms → repository unit tests with fake `AlarmScheduler`

## Porting checklist

When reimplementing on another stack, keep the **same scenarios**; replace runners only:

1. Translate Gherkin to the target’s BDD or keep as manual QA script.
2. Recreate golden baselines for the new UI toolkit (do not reuse Flutter PNGs).
3. Keep coverage gate semantics (measure product code, exclude generated).
4. Fake the repository and alarm scheduler in unit tests; use emulator for integration.
