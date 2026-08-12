import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:driver_schedule/core/theme/theme.dart';
import 'package:driver_schedule/features/drive/domain/entities/drive_type.dart';
import 'package:driver_schedule/features/drive/presentation/bloc/drive/drive_bloc.dart';
import 'package:driver_schedule/features/drive/presentation/bloc/drive/drive_event.dart';
import 'package:driver_schedule/features/drive/presentation/bloc/drive/drive_state.dart';
import 'package:driver_schedule/features/drive/presentation/pages/drive_schedule_screen.dart';

import '../helpers/pump_app.dart';

class MockDriveBloc extends MockBloc<DriveEvent, DriveState> implements DriveBloc {}

@Tags(['golden'])
void main() {
  setUpAll(() async {
    await configureTestEnvironment();
  });

  testWidgets('DriveScheduleScreen empty state golden', (tester) async {
    final bloc = MockDriveBloc();
    whenListen(
      bloc,
      Stream<DriveState>.fromIterable([const DriveLoaded([])]),
      initialState: const DriveLoaded([]),
    );

    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await pumpTestWidget(
      tester,
      const DriveScheduleScreen(filterType: DriveType.trip),
      driveBloc: bloc,
      theme: AppTheme.rcbTheme,
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(DriveScheduleScreen),
      matchesGoldenFile('drive_schedule_empty.png'),
    );
  });
}
