# React Native concepts, explained through this project

## Important context

This repository is a **Flutter** application written in Dart; it does not contain React Native code. The examples below explain common React Native concepts and connect each one to the feature that plays a similar role in this project. React Native snippets are illustrative and are not source files from this repository. Project examples are identified as Flutter/Dart.

The application schedules trips and tickets, stores entries in Cloud Firestore, supports selectable themes, and schedules alarms. Its main architecture is Clean Architecture with BLoC, GetIt, and GoRouter.

## 1. Components and declarative UI

**Concept:** An app UI is built from reusable pieces. In React Native, components are JavaScript or TypeScript functions that return JSX. Declarative rendering means describing what the UI should look like for the current state; the framework updates the screen when that state changes.

**React Native example:**

```tsx
function DriveSummary({ customerName, source, destination }) {
  return (
    <View>
      <Text>{customerName}</Text>
      <Text>{source} → {destination}</Text>
    </View>
  );
}
```

**Project example:** Flutter uses widgets rather than JSX components. `DriveScheduleScreen` composes widgets such as `Column`, `ListView.builder`, `Text`, and `LiquidGlassContainer` to display each drive entry. The list is built from the current `DriveLoaded` state in `lib/features/drive/presentation/pages/drive_schedule_screen.dart`.

## 2. Local state, lifecycle, and hooks

**Concept:** State is data that can change and affect the UI. React's `useState` stores component-local state; lifecycle effects such as `useEffect` run work when a component mounts or when dependencies change. Hooks let function components use these features without class components.

**React Native example:**

```tsx
const [selectedType, setSelectedType] = useState<"trip" | "ticket">("trip");

return (
  <Pressable onPress={() => setSelectedType("ticket")}>
    <Text>{selectedType}</Text>
  </Pressable>
);
```

**Project example:** `AddDriveEntryPage` is a Flutter `HookWidget`. It uses `useState` for the selected date, time, entry type, and alarm offset, and `useTextEditingController` for text fields. For example, choosing a date updates `selectedDate.value`, which the form then uses when it creates a `DriveEntity`. See `lib/features/drive/presentation/pages/add_drive_entry_page.dart`.

The app root is instead a `StatefulWidget`: its `initState` dispatches the initial theme-load and drive-load events (`lib/app.dart`). This is analogous to running setup work when a React component mounts.

## 3. Shared application state

**Concept:** Local component state is appropriate for short-lived UI details; shared state is useful when multiple screens need the same data. React Native apps commonly use Context or libraries such as Redux, Zustand, or XState. These are choices, not built-in React Native requirements.

**React Native example (simplified Context):**

```tsx
const DrivesContext = createContext<Drive[]>([]);

function Schedule() {
  const drives = useContext(DrivesContext);
  return <FlatList data={drives} renderItem={({ item }) => <Text>{item.customerName}</Text>} />;
}
```

**Project example:** The app uses BLoC for shared drive and theme state. A `DriveBloc` accepts events such as `LoadDrivesEvent` and emits states such as `DriveLoading`, `DriveLoaded`, or `DriveError`. `BlocBuilder` rebuilds the schedule when those states change. See `lib/features/drive/presentation/bloc/drive/drive_bloc.dart` and `lib/features/drive/presentation/bloc/drive/drive_state.dart`.

The BLoC pattern makes the flow explicit: **UI event → BLoC event → use case/repository → new BLoC state → updated UI**.

## 4. Navigation and screen state

**Concept:** Navigation maps screens to destinations and manages moving between them, including parameters and back behavior. React Native commonly uses React Navigation; navigation is provided by a library rather than by the core React Native UI components.

**React Native example (React Navigation style):**

```tsx
navigation.navigate("EditDrive", { driveId: entry.id });
```

**Project example:** `GoRouter` defines routes for onboarding, schedule, add-entry, settings, and edit-entry screens. The edit route passes a `DriveEntity` as route data. `StatefulShellRoute.indexedStack` maintains the bottom-navigation branches. See `lib/core/routes/app_router.dart`.

## 5. Forms, inputs, and validation

**Concept:** Forms collect user input, keep its current values, validate them, and submit valid data. React Native provides input primitives such as `TextInput`; validation and date/time pickers are commonly handled by app code or libraries.

**React Native example:**

```tsx
const [customerName, setCustomerName] = useState("");

<TextInput
  value={customerName}
  onChangeText={setCustomerName}
  placeholder="Customer name"
/>
```

**Project example:** The add/edit page keeps text controllers and date/time selections, validates the form, checks that both a date and time were chosen, combines them into a `DateTime`, and dispatches an add or update event. The relevant logic is in `submitForm` in `lib/features/drive/presentation/pages/add_drive_entry_page.dart`.

## 6. Application architecture and dependency injection

**Concept:** Architecture separates responsibilities so UI, business rules, and external services can change independently. Dependency injection (DI) supplies a class with the services it needs rather than having it construct them directly. React Native does not prescribe an architecture or DI library.

**Project example:** This app uses Clean Architecture:

- **Presentation:** pages and BLoCs handle UI and state.
- **Domain:** entities, repository contracts, and use cases express app rules.
- **Data:** repository implementations and Firestore data sources perform persistence.
- **Services:** alarm and notification integrations handle device capabilities.

For instance, `AddDrive` calls the `DriveRepository` contract, while `DriveRepositoryImpl` implements that contract using a Firestore data source and alarm scheduler. `GetIt` registers these dependencies in `lib/injection_container.dart`; the composition avoids tying the use case directly to Firestore.

## 7. Data models, repositories, and serialization

**Concept:** A data model describes the shape and meaning of app data. Serialization converts between the app's model and a transport or storage format such as JSON or a Firestore document. A repository provides the rest of the app a stable way to load and change that data.

**React Native example (TypeScript model):**

```ts
type Drive = {
  id?: string;
  customerName: string;
  source: string;
  destination: string;
  dateTime: string;
  type: "trip" | "ticket";
  alarmOffsetMinutes: number | null;
};
```

**Project example:** `DriveEntity` represents a scheduled entry and implements `fromFirestore` and `toFirestore` to map Firestore documents to and from the app model. `DriveFirestoreDataSourceImpl` performs Firestore reads and writes; `DriveRepositoryImpl` combines that data access with alarm scheduling. See:

- `lib/features/drive/domain/entities/drive_entity.dart`
- `lib/features/drive/data/datasources/drive_firestore_data_source.dart`
- `lib/features/drive/data/repositories/drive_repository_impl.dart`

## 8. Asynchronous work and loading/error states

**Concept:** Network and device operations take time. In React Native, promises and `async`/`await` are commonly used; the UI should represent loading, success, empty, and failure outcomes rather than blocking while work runs.

**React Native example:**

```tsx
const [loading, setLoading] = useState(true);
const [drives, setDrives] = useState<Drive[]>([]);

useEffect(() => {
  loadDrives()
    .then(setDrives)
    .finally(() => setLoading(false));
}, []);
```

**Project example:** The drive BLoC awaits the `GetDrives` use case and emits a loading state before the result, a loaded state on success, or an error state on failure. `DriveScheduleScreen` renders a progress indicator, error message, empty state, or entry list based on the emitted state. See `lib/features/drive/presentation/bloc/drive/drive_bloc.dart` and `lib/features/drive/presentation/pages/drive_schedule_screen.dart`.

## 9. Backend integration and cloud persistence

**Concept:** A mobile app often reads and writes data through a backend SDK. React Native can use the Firebase JavaScript SDK or a React Native Firebase package. Firestore is a cloud document database; it is distinct from local device storage.

**Project example:** The app uses Flutter's `cloud_firestore` package. `DriveFirestoreDataSourceImpl` orders entries by `dateTime`, creates and updates documents, deletes by ID, and seeds mock entries when the collection is empty. Firebase setup and optional Firestore emulator configuration are handled in `lib/core/firebase/` and `lib/bootstrap.dart`.

## 10. Device-local persistence

**Concept:** Local persistence stores small values on a device, for example onboarding completion or a selected theme. Ordinary preferences and sensitive values are different concerns; secrets should use secure storage. In React Native, common choices include AsyncStorage for preferences and a secure-storage package for protected values.

**Project example:** `ThemeBloc` reads and writes the selected theme key using `FlutterSecureStorage` (`lib/features/settings/presentation/bloc/theme/theme_bloc.dart`). The project also depends on `shared_preferences`; the onboarding page uses it to persist onboarding completion (`lib/features/settings/presentation/pages/onboarding_page.dart`). These device-local values are separate from drive entries stored in Firestore.

## 11. Notifications, alarms, and native capabilities

**Concept:** Notifications, exact alarms, haptics, and permissions rely on operating-system capabilities, so an app uses platform APIs or packages that bridge to them. In React Native, packages such as Expo Notifications or Notifee are typical approaches; availability and behavior can differ by platform.

**Project example:** `AlarmService` schedules and cancels trip reminders using the `alarm` package. It calculates the alarm time from the drive date and configured offset, and skips alarms that are already in the past. `NotificationService` configures local notifications and requests platform permissions. The schedule list also calls `HapticFeedback.selectionClick()` when an entry is tapped. See `lib/services/alarm_service.dart`, `lib/services/notification_service.dart`, and `lib/features/drive/presentation/pages/drive_schedule_screen.dart`.

## 12. Styling, design systems, and themes

**Concept:** Styling controls layout, spacing, color, typography, and visual states. A design system centralizes those choices so screens stay consistent. React Native includes `StyleSheet` for defining style objects; libraries can add higher-level theming or design-system components.

**React Native example:**

```tsx
const styles = StyleSheet.create({
  card: { padding: 16, borderRadius: 10 },
});
```

**Project example:** Flutter uses widget properties and `ThemeData` rather than `StyleSheet`. `AppTheme` builds Material 3 themes with color schemes, typography, component styling, and a custom background extension. The app offers ten selectable IPL-inspired themes. See `lib/core/theme/theme.dart` and `lib/features/settings/presentation/bloc/theme/`.

## 13. Lists and animations

**Concept:** Lists efficiently render repeated content. React Native's `FlatList` virtualizes rows so large lists need not be fully rendered at once. Animation libraries can add transitions and feedback.

**React Native example:**

```tsx
<FlatList
  data={drives}
  keyExtractor={(item) => item.id!}
  renderItem={({ item }) => <DriveSummary {...item} />}
/>
```

**Project example:** `ListView.builder` lazily builds the visible Flutter schedule entries. The list uses `flutter_staggered_animations` for slide-and-fade entry animations and a liquid-glass container for card styling. See `lib/features/drive/presentation/pages/drive_schedule_screen.dart`.

## 14. Testing

**Concept:** Tests check behavior at different levels. Unit tests exercise logic, component/widget tests verify UI behavior, and integration tests cover end-to-end flows. In React Native, Jest and React Native Testing Library are commonly used; those are not used by this Flutter repository.

**Project example:** This app uses `flutter_test` for unit and widget tests, `bloc_test` for BLoC behavior, `mocktail` for fakes/mocks, golden tests for visual snapshots, and Flutter integration tests for user flows. Test files are organized under `test/` and `integration_test/`; test setup can use in-memory repositories and `AppBootstrapConfig.testing()`.

## 15. Cross-platform targets and project tooling

**Concept:** Cross-platform frameworks share much of the application code while still requiring platform-specific setup, permissions, and packaging. React Native projects commonly include Android and iOS native projects alongside JavaScript/TypeScript source; additional targets and tooling depend on the chosen stack.

**Project example:** Flutter compiles this app for Android and iOS, and the repository also has platform folders for web, Windows, macOS, and Linux. Firebase configuration, alarm permissions, and notification behavior still need platform-specific setup. The documented Flutter commands are `flutter pub get` and `flutter run`; Flutter's analyzer, test runner, and the repository's CI scripts provide validation.

## Quick comparison

| Concern | React Native example | This project's implementation |
|---|---|---|
| UI | JSX components (`View`, `Text`) | Flutter widgets |
| Local UI state | `useState`, `useEffect` | `flutter_hooks`, `StatefulWidget` |
| Shared state | Context, Redux, Zustand, etc. | BLoC (`flutter_bloc`) |
| Navigation | React Navigation | GoRouter |
| Dependency injection | Context or DI library | GetIt |
| Cloud data | Firebase JS SDK / React Native Firebase | Cloud Firestore Flutter package |
| Local preferences | AsyncStorage / secure-storage package | Shared Preferences and Flutter Secure Storage |
| Styling | `StyleSheet` or styling library | Material 3 `ThemeData` and widget styling |
| Tests | Jest / React Native Testing Library | `flutter_test`, `bloc_test`, integration tests |

The comparison is conceptual: the React Native column describes common options, not dependencies or code currently present in this repository.
