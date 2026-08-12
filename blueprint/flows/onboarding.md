# Flow: Onboarding

## Entry

App launch AND `has_seen_onboarding != true`.

## Steps

1. Show page 1 — Schedule & Filter
2. User taps **Next** → page 2 — Smart Reminders
3. User taps **Next** → page 3 — Easy Management
4. User taps **Get Started**
5. Persist `has_seen_onboarding = true`
6. Navigate to Schedule home (`/`)

## Exit

Subsequent launches skip onboarding and open Schedule (or last shell tab — default Schedule).

## Acceptance

See `qa/acceptance.feature` scenarios under Onboarding.
