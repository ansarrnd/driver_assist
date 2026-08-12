import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:driver_schedule/features/settings/presentation/bloc/theme/theme_event.dart';
import 'package:driver_schedule/features/settings/presentation/bloc/theme/theme_state.dart';
import 'package:driver_schedule/features/settings/presentation/pages/theme_selection_page.dart';

import '../helpers/pump_app.dart';
import '../helpers/theme_test_helpers.dart';

void main() {
  setUpAll(() async {
    await configureTestEnvironment();
  });

  for (final type in ThemeType.values) {
    testWidgets('ThemeSelectionPage golden for ${type.name}', (tester) async {
      final bloc = MockThemeBloc();
      final state = themeStateFor(type);
      whenListen(
        bloc,
        Stream<ThemeState>.fromIterable([state]),
        initialState: state,
      );

      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await pumpTestWidget(
        tester,
        const ThemeSelectionPage(),
        themeBloc: bloc,
        theme: state.themeData,
      );
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(ThemeSelectionPage),
        matchesGoldenFile('theme_selection_${type.name}.png'),
      );
    });
  }
}
