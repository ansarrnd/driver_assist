# Domain rules

## Drive persistence

1. A new Drive may be created without `id`.
2. After create, persistence returns a non-empty `id`.
3. Update and delete require a non-null `id`.
4. Listing is ordered by `dateTime` descending (newest/latest first in query; UI may display as returned).

## Filtering (`filterDriveEntries`)

Pure function — no I/O.

Inputs: `entries[]`, `type`, `period`, optional `referenceTime` (defaults to now).

1. Keep entries where `entry.type == type`.
2. Normalize `today` = date-only of `referenceTime`.
3. **today** — entry calendar date equals `today`.
4. **week** — Monday-start week: `start = today - (weekday-1)`, `end = start + 6 days`; include entry dates in `[start, end]`.
5. **month** — same calendar year and month as `referenceTime`.

## Alarm scheduling

Let `alarmAt = dateTime - Duration(minutes: alarmOffsetMinutes)`.

| Condition | Action |
|-----------|--------|
| `id` is null | Do not schedule |
| `alarmOffsetMinutes` is null | Cancel any existing alarm for id |
| `alarmAt < now` | Do not schedule; cancel existing if any |
| otherwise | Schedule alarm at `alarmAt` |

Alarm identity: stable integer derived from string id  
(reference: `hash(id) & 0x7FFFFFFF` — any stable mapping is fine in other stacks).

Alarm payload (user):

- Title: `Time to Drive! ({customerName})`
- Body: `Upcoming trip from {source} to {destination}. Drive safely!`
- Audio: looping alarm sound; vibrate on

## Seed

On first successful read of an empty `drive_entries` collection, insert the mock seed set (see `data/seed.sample.json`). Do not re-seed if any document exists.

## Theme

- Persisted theme id must be one of `ThemeId` values.
- Unknown / missing → `rcb`.
