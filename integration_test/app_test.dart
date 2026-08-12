import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:driver_schedule/app.dart';
import 'package:driver_schedule/bootstrap.dart';
import 'package:driver_schedule/features/drive/presentation/bloc/drive/drive_bloc.dart';
import 'package:driver_schedule/features/drive/presentation/bloc/drive/drive_event.dart';
import 'package:driver_schedule/features/settings/presentation/bloc/theme/theme_bloc.dart';
import 'package:driver_schedule/injection_container.dart' as di;

import '../test/helpers/fakes.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Driver Schedule integration', () {
    Future<void> pumpApp(
      WidgetTester tester, {
      InMemoryDriveRepository? repository,
      bool hasSeenOnboarding = true,
    }) async {
      final repo = repository ?? InMemoryDriveRepository();
      await bootstrapApp(
        AppBootstrapConfig.testing(
          hasSeenOnboarding: hasSeenOnboarding,
          testDriveRepository: repo,
        ),
      );

      await tester.pumpWidget(
        DriverScheduleRoot(
          themeBloc: di.sl<ThemeBloc>(),
          driveBloc: di.sl<DriveBloc>(),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('bootstraps test app and shows schedule tab', (tester) async {
      await pumpApp(tester);

      expect(find.text('Drive Schedule'), findsOneWidget);
      expect(find.text('Schedule'), findsOneWidget);
    });

    testWidgets('navigates to add tab', (tester) async {
      await pumpApp(tester);

      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();

      expect(find.text('Add Entry'), findsOneWidget);
    });

    testWidgets('shows seeded drive entry in schedule', (tester) async {
      final repository = InMemoryDriveRepository();
      repository.seed(
        testDrive(
          id: 'seed-1',
          customerName: 'Integration User',
          dateTime: DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day, 12),
        ),
      );

      await pumpApp(tester, repository: repository);

      expect(find.text('Integration User'), findsOneWidget);
    });

    testWidgets('shows onboarding on first launch', (tester) async {
      await pumpApp(tester, hasSeenOnboarding: false);

      expect(find.text('Schedule & Filter'), findsOneWidget);
      expect(find.text('Next'), findsOneWidget);
    });
  });
}
