import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:driver_schedule/app.dart';
import 'package:driver_schedule/bootstrap.dart';
import 'package:driver_schedule/features/drive/presentation/bloc/drive/drive_bloc.dart';
import 'package:driver_schedule/features/settings/presentation/bloc/theme/theme_bloc.dart';
import 'package:driver_schedule/injection_container.dart' as di;

import '../test/helpers/fakes.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Driver Schedule integration', () {
    testWidgets('bootstraps test app and shows schedule tab', (tester) async {
      await bootstrapApp(
        AppBootstrapConfig.testing(
          testDriveRepository: InMemoryDriveRepository(),
        ),
      );

      await tester.pumpWidget(
        DriverScheduleRoot(
          themeBloc: di.sl<ThemeBloc>(),
          driveBloc: di.sl<DriveBloc>(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Drive Schedule'), findsOneWidget);
      expect(find.text('Schedule'), findsOneWidget);
    });

    testWidgets('navigates to add tab', (tester) async {
      await bootstrapApp(
        AppBootstrapConfig.testing(
          testDriveRepository: InMemoryDriveRepository(),
        ),
      );

      await tester.pumpWidget(
        DriverScheduleRoot(
          themeBloc: di.sl<ThemeBloc>(),
          driveBloc: di.sl<DriveBloc>(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();

      expect(find.text('Add Entry'), findsOneWidget);
    });
  });
}
