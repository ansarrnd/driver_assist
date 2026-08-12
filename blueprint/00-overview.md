# Driver Schedule — Portable Blueprint

Framework-agnostic specification extracted from the Flutter `driver_schedule` app so the product can be reimplemented in React Native, SwiftUI, Kotlin Multiplatform, Compose, or any other stack.

## Principle

Document **contracts, rules, and journeys** — not Flutter widgets, BLoC classes, or plugin APIs.

```
Blueprint (this folder)     →  WHAT the product is
Framework adapters          →  HOW it is built (Flutter / RN / native)
```

## Contents

| Path | Purpose |
|------|---------|
| [`domain/`](domain/) | Entities, enums, invariants, use cases |
| [`design/`](design/) | Tokens, screens, reusable UI patterns |
| [`flows/`](flows/) | User journeys end-to-end |
| [`data/`](data/) | Firestore schema, seed, local storage keys |
| [`platform/`](platform/) | Alarms, notifications, permissions |
| [`qa/`](qa/) | Acceptance criteria (Gherkin) + coverage gates |
| [`porting/`](porting/) | Adapter map and non-goals |

## Suggested porting order

1. Implement **domain** + unit tests from `qa/acceptance.feature` (domain scenarios)
2. Implement **data ports** (Firestore + local prefs)
3. Implement **Schedule list** vertical slice
4. Add **Add/Edit/Delete** + alarm port
5. Add **onboarding** + **themes**
6. Match **design tokens** and screenshot baselines
7. Run full acceptance suite — port is done when it passes

## Product one-liner

A driver scheduling app for trips and tickets, with period filters, reminder alarms, and IPL-team visual themes, backed by Cloud Firestore.
