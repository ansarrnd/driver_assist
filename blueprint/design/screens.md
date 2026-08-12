# Screens

## Navigation map

```text
[first launch] → Onboarding → Schedule (shell)
                              ├─ Add (shell tab)
                              └─ Settings (shell tab)
                                   ├─ App Theme
                                   └─ Manage Drive Entries
Schedule list item tap → Edit Drive (modal/stack over shell)
```

## Screen catalog

| ID | Title | Route concept | Primary actions |
|----|-------|---------------|-----------------|
| `onboarding` | (none) | `/onboarding` | Next, Get Started |
| `schedule` | Drive Schedule | `/` | Filter period, open trip/ticket tabs, tap row → edit |
| `add_drive` | (form in tab) | `/add-drive` | Submit Add Entry |
| `edit_drive` | Edit Drive Entry | `/edit-drive` | Submit Update Entry |
| `settings` | Settings | `/settings` | Open theme / manage |
| `theme_selection` | App Theme | pushed | Select theme chip |
| `manage_entries` | Manage Drive Entries | pushed | Swipe delete, tap edit |

## Schedule list row content

- Customer name (emphasis)
- Alarm icon if `alarmOffsetMinutes != null`
- Edit affordance icon
- Date & time line
- Source/Pickup line
- Destination/Drop line

## Add / Edit form fields

| Field | Control | Notes |
|-------|---------|-------|
| Type | Radio Trip / Ticket | Disabled when editing |
| Customer Name | Text | required |
| Date | Date picker | required |
| Time | Time picker | required |
| Source / Pickup | Text | label by type |
| Destination / Drop | Text | label by type |
| Reminder Alarm | Dropdown | null, 0, 15, 30, 60, 1440; default 1440 on create |

## Empty / loading / error

- Loading: centered progress indicator
- Error: `Error: {message}`
- Empty schedule: icon + “No drive schedules available.”
- Empty manage: “No trips/tickets scheduled” + supporting line
