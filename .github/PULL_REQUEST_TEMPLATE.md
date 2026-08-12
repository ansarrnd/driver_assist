## Pull request checklist

- [ ] `dart format` clean on `lib/`, `test/`, `integration_test/`, `tool/`
- [ ] `flutter analyze` clean
- [ ] `bash tool/check_coverage.sh` passes
- [ ] Golden tests updated if UI changed (`flutter test test/goldens --update-goldens`)
- [ ] Integration flows considered if navigation/CRUD/alarms changed
- [ ] README / docs updated when setup or architecture changes
- [ ] No secrets (`key.properties`, real Firebase keys, keystores) committed
