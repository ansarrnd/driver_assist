# Flow: Schedule & filter

## Entry

Shell tab Schedule (default after onboarding).

## Steps

1. App loads drives (Loading → Loaded or Error)
2. User sees Trips / Tickets tabs (default Trips)
3. User optionally changes period filter (default Month)
4. List shows filtered drives as GlassCards
5. Tap row → Edit Drive flow

## Filtering

`filter(entries, type, period, now)` — see `domain/rules.md`.

## Empty

If no matches: empty state copy on schedule screen.

## Side effects

None beyond initial GetDrives (which may seed).
