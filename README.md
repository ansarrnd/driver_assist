# Driver Schedule

A Flutter driver scheduling app with Firestore backend, trip/ticket management, IPL team themes, and reminder alarms.

## Features

- Schedule **trips** and **tickets** with customer, pickup/source, destination, and datetime
- **Cloud Firestore** backend with automatic mock data seeding on first launch
- Custom **alarm reminders** (15 min, 30 min, 1 hour, 1 day before, or at trip time)
- Filter schedule by Today / Week / Month
- 10 IPL-inspired themes
- Onboarding flow for first-time users

## Firebase setup

1. Create a Firebase project at https://console.firebase.google.com
2. Enable **Cloud Firestore**
3. Run:
   ```bash
   dart pub global activate flutterfire_cli
   flutterfire configure
   ```
4. Replace the placeholder `lib/core/firebase/firebase_options.dart` and `android/app/google-services.json` with generated files.

### Firestore collection

Collection: `drive_entries`

Document fields:

| Field | Type | Description |
|-------|------|-------------|
| `customerName` | string | Customer name |
| `source` | string | Pickup / source location |
| `destination` | string | Drop / destination location |
| `dateTime` | string (ISO8601) | Scheduled datetime |
| `type` | string | `trip` or `ticket` |
| `alarmOffsetMinutes` | int? | Minutes before trip to trigger alarm |

Mock seed data lives in `assets/mock/firestore_drive_entries.json` and is written automatically when the collection is empty.

### Local development with emulator

Uncomment the emulator line in `lib/core/firebase/firebase_initializer.dart` and run:

```bash
firebase emulators:start --only firestore
```

## Getting started

```bash
flutter pub get
flutter run
```

## Architecture

Clean architecture with BLoC:

- **Presentation**: pages + `DriveBloc` / `ThemeBloc`
- **Domain**: entities, repositories, use cases
- **Data**: Firestore data source, repository implementation
- **Services**: alarms and notifications

Alarm scheduling is handled in the repository layer (not the UI), including reschedule on app startup and cancel on delete.

## Testing

```bash
# Unit + widget tests
flutter test --exclude-tags golden

# Golden/snapshot tests (baselines committed under test/goldens/)
flutter test test/goldens

# Integration tests (device/emulator required)
flutter test integration_test
```

Test layout:

| Directory | Purpose |
|-----------|---------|
| `test/domain/` | Entity, filter, and repository fakes |
| `test/data/` | `DriveRepositoryImpl` with fake Firestore |
| `test/presentation/` | BLoC and widget tests |
| `test/goldens/` | Snapshot/golden tests (`@Tags(['golden'])`) |
| `integration_test/` | End-to-end flows with in-memory repository |
| `test/helpers/` | `pump_app`, fakes, and shared fixtures |

Integration and widget tests use `initForTesting()` / `AppBootstrapConfig.testing()` to avoid Firebase and native alarm initialization.
