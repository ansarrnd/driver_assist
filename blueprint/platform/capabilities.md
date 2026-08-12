# Platform capabilities

Contracts that require OS-level APIs. Each target must implement these adapters.

## Alarms (`AlarmScheduler`)

| Method | Behavior |
|--------|----------|
| `schedule(id, fireAt, title, body)` | Exact / inexact alarm at `fireAt` |
| `cancel(id)` | Cancel pending alarm for drive id |
| `cancelAll()` | Optional; cancel all app alarms |
| `rescheduleAll(entries)` | Called at bootstrap after load |

### Rules

1. Schedule **after** successful create/update persist (use returned id).
2. Cancel **before or after** delete persist (must not leave orphan alarms).
3. On cold start, reschedule all future drives from repository snapshot.
4. If `fireAt` is in the past, skip schedule (or schedule immediately — pick one and document).
5. Notification payload should deep-link intent to schedule screen when possible.

### Flutter reference

- `flutter_local_notifications` + Android `AlarmManager` / iOS local notifications
- Exact alarms may need `SCHEDULE_EXACT_ALARM` / user permission on Android 12+

## Notifications

| Concern | Contract |
|---------|----------|
| Channel | Dedicated channel id e.g. `drive_reminders` |
| Title | Prefer customer name or “Drive reminder” |
| Body | Source → destination + time |
| Permission | Request on first alarm schedule or onboarding |

## Permissions matrix

| Permission | When needed | Denial behavior |
|------------|-------------|-----------------|
| Notifications | Before first reminder | Persist drives; show in-app banner that reminders are off |
| Exact alarms (Android) | Precise reminders | Fall back to inexact or notify user |
| Internet | Firestore sync | Offline cache if SDK supports; else error state |

## Bootstrap sequence

```
1. Init DI / Firebase
2. (Optional) Connect Firestore emulator if env set
3. Load preferences (onboarding, theme)
4. Load drives (seed if empty)
5. Reschedule alarms for future drives
6. Show Onboarding OR Schedule
```

## Non-portable platform notes

Do **not** put these in domain:

- Firebase options / `google-services.json`
- Flutter plugin channel names
- Exact Android manifest permissions XML
- iOS Info.plist keys

Document them only in target-specific `platform/<os>.md` when porting.
