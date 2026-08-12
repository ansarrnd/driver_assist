# UI component patterns

Framework-agnostic patterns to reimplement (names are conceptual).

## GlassCard

- Frosted / translucent panel over gradient background
- Blur ~15, fill opacity ~0.1, radius 10
- Used for list rows, settings tiles, add form container

## ScheduleRow

- Composed inside GlassCard
- Shows identity + route + time
- Optional alarm badge
- Entire row tappable → edit

## PeriodFilterDropdown

- Values: Today, Week, Month
- Default: Month
- Client-side only; does not refetch server by period

## TypeTabs

- Trips | Tickets
- Filters by `DriveType` before period filter

## ThemeChip

- Color swatch + short code (RCB, CSK, …)
- Selected state: stronger border + tinted background
- One selected at a time

## ConfirmDeleteDialog

- Title: Confirm Deletion
- Body: Are you sure you want to delete this entry?
- Actions: Cancel / Delete (destructive)

## OnboardingPager

- 3 pages with icon, title, description
- Page indicator
- Next until last → Get Started

### Copy

1. **Schedule & Filter** — Easily manage your Trips and Tickets in one unified schedule.
2. **Smart Reminders** — Set up custom alarms and notifications so you are never late for a pickup.
3. **Easy Management** — Tap an entry to edit its details, or simply swipe left to delete it.

## Motion

- Staggered list entrance (fade + slide up) on schedule rows — optional but present in reference app
- Keep motion subtle; not required for functional parity
