# Flow: Alarms lifecycle

```text
Cold start
  → init alarm subsystem
  → GetDrives / list
  → RescheduleAlarms for all drives with future alarmAt

AddDrive
  → persist → schedule(id)

UpdateDrive
  → persist → schedule(id)   # or cancel if offset null / past

DeleteDrive
  → delete → cancel(id)
```

## Device requirements

- Notification permission
- Exact alarm permission where required (Android 12+)
- Optional: survive reboot via platform boot receivers (reference Android app registers boot handlers)

## Failure modes

- Missing id → no schedule
- Past alarmAt → no schedule
- User denies permission → persist still succeeds; alarm may not fire (document as known limitation)
