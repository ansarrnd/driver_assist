import 'package:bloc_test/bloc_test.dart';
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

  testWidgets('renders all IPL theme options', (tester) async {
    final bloc = MockThemeBloc();
    final state = themeStateFor(ThemeType.rcb);
    whenListen(
      bloc,
      Stream<ThemeState>.fromIterable([state]),
      initialState: state,
    );

    await pumpTestWidget(
      tester,
      const ThemeSelectionPage(),
      themeBloc: bloc,
      theme: state.themeData,
    );
    await tester.pumpAndSettle();

    for (final type in ThemeType.values) {
      expect(find.text(themeLabel(type)), findsOneWidget);
    }
  });
}
