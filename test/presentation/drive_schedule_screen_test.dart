import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:driver_schedule/features/drive/domain/entities/drive_type.dart';
import 'package:driver_schedule/features/drive/presentation/bloc/drive/drive_bloc.dart';
import 'package:driver_schedule/features/drive/presentation/bloc/drive/drive_event.dart';
import 'package:driver_schedule/features/drive/presentation/bloc/drive/drive_state.dart';
import 'package:driver_schedule/features/drive/presentation/pages/drive_schedule_screen.dart';

import '../helpers/fakes.dart';
import '../helpers/pump_app.dart';

class MockDriveBloc extends MockBloc<DriveEvent, DriveState>
    implements DriveBloc {}

void main() {
  setUpAll(() async {
    await configureTestEnvironment();
  });

  group('DriveScheduleScreen', () {
    testWidgets('shows empty state when no drives match filter', (
      tester,
    ) async {
      final bloc = MockDriveBloc();
      whenListen(
        bloc,
        Stream<DriveState>.fromIterable([const DriveLoaded([])]),
        initialState: const DriveLoaded([]),
      );

      await pumpTestWidget(
        tester,
        const DriveScheduleScreen(filterType: DriveType.trip),
        driveBloc: bloc,
      );
      await tester.pumpAndSettle();

      expect(find.text('No drive schedules available.'), findsOneWidget);
    });

    testWidgets('renders drive cards for loaded state', (tester) async {
      final drives = [
        testDrive(
          id: '1',
          customerName: 'Alice',
          dateTime: DateTime(DateTime.now().year, DateTime.now().month, 12, 10),
        ),
      ];
      final bloc = MockDriveBloc();
      whenListen(
        bloc,
        Stream<DriveState>.fromIterable([DriveLoaded(drives)]),
        initialState: DriveLoaded(drives),
      );

      await pumpTestWidget(
        tester,
        const DriveScheduleScreen(filterType: DriveType.trip),
        driveBloc: bloc,
      );
      await tester.pumpAndSettle();

      expect(find.text('Alice'), findsOneWidget);
      expect(find.textContaining('Pickup: Pickup Point'), findsOneWidget);
    });

    testWidgets('shows error message on failure', (tester) async {
      final bloc = MockDriveBloc();
      whenListen(
        bloc,
        Stream<DriveState>.fromIterable([const DriveError('boom')]),
        initialState: const DriveError('boom'),
      );

      await pumpTestWidget(
        tester,
        const DriveScheduleScreen(filterType: DriveType.trip),
        driveBloc: bloc,
      );
      await tester.pumpAndSettle();

      expect(find.text('Error: boom'), findsOneWidget);
    });
  });
}
