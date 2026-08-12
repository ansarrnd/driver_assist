import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:driver_schedule/app.dart';
import 'package:driver_schedule/bootstrap.dart';
import 'package:driver_schedule/features/drive/presentation/bloc/drive/drive_bloc.dart';
import 'package:driver_schedule/features/settings/presentation/bloc/theme/theme_bloc.dart';
import 'package:driver_schedule/features/settings/presentation/bloc/theme/theme_event.dart';
import 'package:driver_schedule/injection_container.dart' as di;

import '../test/helpers/fakes.dart';
import 'helpers/test_actions.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Driver Schedule integration', () {
    Future<InMemoryDriveRepository> pumpApp(
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
      return repo;
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
          dateTime: DateTime(
            DateTime.now().year,
            DateTime.now().month,
            DateTime.now().day,
            12,
          ),
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

    testWidgets('completes onboarding and lands on schedule', (tester) async {
      await pumpApp(tester, hasSeenOnboarding: false);

      await completeOnboarding(tester);

      expect(find.text('Drive Schedule'), findsOneWidget);
    });

    testWidgets('adds a drive entry through the form', (tester) async {
      await pumpApp(tester);

      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();

      await fillAddDriveForm(
        tester,
        customerName: 'Form User',
        source: 'Airport',
        destination: 'Downtown',
      );

      await tester.ensureVisible(find.text('Add Entry'));
      await tester.tap(find.text('Add Entry'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Schedule'));
      await tester.pumpAndSettle();

      expect(find.text('Form User'), findsWidgets);
    });

    testWidgets('deletes a drive entry via swipe in manage entries', (
      tester,
    ) async {
      final repository = InMemoryDriveRepository();
      repository.seed(
        testDrive(
          id: 'delete-me',
          customerName: 'Delete Me',
          dateTime: DateTime(
            DateTime.now().year,
            DateTime.now().month,
            DateTime.now().day,
            14,
          ),
        ),
      );

      await pumpApp(tester, repository: repository);

      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Manage Drive Entries'));
      await tester.pumpAndSettle();

      expect(find.text('Delete Me'), findsOneWidget);

      await swipeToDeleteEntry(tester, 'Delete Me');

      expect(find.text('Delete Me'), findsNothing);
      expect(await repository.getDrives(), isEmpty);
    });

    testWidgets('opens theme selection from settings', (tester) async {
      await pumpApp(tester);

      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('App Theme'));
      await tester.pumpAndSettle();

      expect(find.text('RCB'), findsOneWidget);
      expect(find.text('CSK'), findsOneWidget);
      expect(find.text('MI'), findsOneWidget);

      await tester.tap(find.text('CSK'));
      await tester.pumpAndSettle();

      expect(di.sl<ThemeBloc>().state.themeType, ThemeType.csk);
    });
  });
}
