# Local & preference storage keys

Portable key names used by the reference Flutter app. Reimplement with the
target platform’s preference / key-value store.

| Key | Type | Default | Purpose |
|-----|------|---------|---------|
| `has_seen_onboarding` | bool | `false` | Skips intro after first completion |
| `selected_theme` | string | `rcb` | Theme pack id (`rcb`, `csk`, `mi`, … `gt`) |

## Notes

- Reference app stores `selected_theme` via secure storage; any durable KV store is fine when porting.
- Theme pack ids must match `design/tokens.yaml` → `themes` keys / `domain/model.yaml` → `ThemeId`.
- Clearing app data must reset onboarding and theme to defaults.
- No PII is stored in preferences; drive data lives in Firestore only.
