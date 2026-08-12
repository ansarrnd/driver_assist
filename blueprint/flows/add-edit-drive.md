# Flow: Add / Edit drive

## Add — entry

Shell tab **Add**.

## Add — steps

1. Optional: choose Trip or Ticket (default Trip)
2. Enter customer, date, time, source, destination
3. Optional: change alarm offset (default 1 day = 1440)
4. Tap **Add Entry**
5. Validate — show field errors if empty
6. On success: persist + schedule alarm + snackbar + clear form

## Edit — entry

From Schedule or Manage Entries → tap row → Edit screen with entry prefilled.

## Edit — steps

1. Type radio disabled
2. Change fields / alarm
3. Tap **Update Entry**
4. Persist update + reschedule/cancel alarm as rules dictate
5. Snackbar + navigate back

## Alarm options

| Value | Label |
|------:|-------|
| null | None (Remove Alarm) |
| 0 | At time of trip |
| 15 | 15 minutes before |
| 30 | 30 minutes before |
| 60 | 1 hour before |
| 1440 | 1 day before |
