# Adapter map — Flutter → other frameworks

How each blueprint surface maps to a typical target stack. Replace the
“Flutter reference” column when porting; keep domain/contracts stable.

| Blueprint area | Flutter reference | React Native / Expo | SwiftUI + Combine | Kotlin Compose | Web (React) |
|----------------|-------------------|---------------------|-------------------|----------------|-------------|
| Domain entities | `lib/features/drive/domain` | Plain TS types + zod | Swift structs | data classes | TS types |
| Use cases | `domain/usecases` | functions / services | actors / use-case types | UseCase classes | hooks / services |
| State | BLoC / Cubit | Redux / Zustand / XState | `@Observable` / TCA | ViewModel + StateFlow | Redux / Zustand |
| DI | GetIt | context / DI lib | Environment | Hilt / Koin | context |
| Firestore | `cloud_firestore` | `@react-native-firebase/firestore` or JS SDK | Firebase iOS SDK | Firebase Android SDK | Firebase JS SDK |
| Local prefs | `shared_preferences` | AsyncStorage | UserDefaults | DataStore | localStorage |
| Alarms | local notifications + AlarmManager | Notifee / expo-notifications | UNUserNotificationCenter | AlarmManager + WorkManager | Web Push / service worker (limited) |
| Navigation | GoRouter / Navigator | React Navigation | NavigationStack | Navigation Compose | React Router |
| Theming | ThemeData + packs | StyleSheet / Tamagui | Asset catalog + Color | MaterialTheme | CSS variables from `tokens.yaml` |
| Tests | flutter_test + goldens | Jest + Testing Library | XCTest | JUnit + Compose tests | Vitest + Playwright |
| CI | `tool/ci_local.sh` + GHA | same gates, different runners | Xcode Cloud / GHA | Gradle + GHA | GHA |

## Porting order (recommended)

1. **Domain** — entities, rules, use cases (no UI).
2. **Data** — Firestore schema + repository interface + seed.
3. **Platform adapters** — prefs, alarms, permissions.
4. **State + screens** — schedule, form, themes, onboarding.
5. **Design tokens** — map `tokens.yaml` to native theme.
6. **QA** — recreate acceptance scenarios and coverage gates.

## File → concern index

| Path | Concern |
|------|---------|
| `domain/model.yaml` | Canonical fields & enums |
| `domain/rules.md` | Invariants & alarm timing |
| `domain/usecases.yaml` | Application API |
| `design/tokens.yaml` | Color/type/spacing packs |
| `design/screens.md` | Screen inventory & layout jobs |
| `design/components.md` | Reusable UI pieces |
| `flows/*.md` | User journeys |
| `data/firestore-schema.json` | Backend shape |
| `data/seed-sample.json` | Demo content |
| `data/storage-keys.md` | Preference keys |
| `platform/capabilities.md` | OS contracts |
| `qa/acceptance.feature` | BDD scenarios |
| `qa/coverage-gates.md` | Quality bar |
| `porting/non-goals.md` | What not to copy |
