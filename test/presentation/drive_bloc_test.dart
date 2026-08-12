import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:driver_schedule/core/usecases/usecase.dart';
import 'package:driver_schedule/features/drive/domain/usecases/add_drive.dart';
import 'package:driver_schedule/features/drive/domain/usecases/delete_drive.dart';
import 'package:driver_schedule/features/drive/domain/usecases/get_drives.dart';
import 'package:driver_schedule/features/drive/domain/usecases/update_drive.dart';
import 'package:driver_schedule/features/drive/presentation/bloc/drive/drive_bloc.dart';
import 'package:driver_schedule/features/drive/presentation/bloc/drive/drive_event.dart';
import 'package:driver_schedule/features/drive/presentation/bloc/drive/drive_state.dart';

import '../helpers/fakes.dart';

class MockGetDrives extends Mock implements GetDrives {}

class MockAddDrive extends Mock implements AddDrive {}

class MockUpdateDrive extends Mock implements UpdateDrive {}

class MockDeleteDrive extends Mock implements DeleteDrive {}

void main() {
  late MockGetDrives getDrives;
  late MockAddDrive addDrive;
  late MockUpdateDrive updateDrive;
  late MockDeleteDrive deleteDrive;
  late DriveBloc bloc;
  final sampleDrives = [
    testDrive(id: '1'),
    testDrive(id: '2', customerName: 'Other'),
  ];

  setUpAll(() {
    registerFallbackValue(testDrive());
    registerFallbackValue(NoParams());
  });

  setUp(() {
    getDrives = MockGetDrives();
    addDrive = MockAddDrive();
    updateDrive = MockUpdateDrive();
    deleteDrive = MockDeleteDrive();
    bloc = DriveBloc(
      getDrives: getDrives,
      addDrive: addDrive,
      updateDrive: updateDrive,
      deleteDrive: deleteDrive,
    );
  });

  tearDown(() => bloc.close());

  group('DriveBloc', () {
    blocTest<DriveBloc, DriveState>(
      'emits loading then loaded on initial load',
      build: () {
        when(() => getDrives(any())).thenAnswer((_) async => sampleDrives);
        return bloc;
      },
      act: (bloc) => bloc.add(const LoadDrivesEvent()),
      expect: () => [isA<DriveLoading>(), DriveLoaded(sampleDrives)],
    );

    blocTest<DriveBloc, DriveState>(
      'silent reload does not emit loading when already loaded',
      build: () {
        when(() => getDrives(any())).thenAnswer((_) async => sampleDrives);
        return bloc;
      },
      seed: () => DriveLoaded(sampleDrives),
      act: (bloc) => bloc.add(const LoadDrivesEvent(silent: true)),
      expect: () => <DriveState>[],
    );

    blocTest<DriveBloc, DriveState>(
      'add drive triggers silent reload',
      build: () {
        when(() => addDrive(any())).thenAnswer((_) async => 'new-id');
        when(() => getDrives(any())).thenAnswer((_) async => sampleDrives);
        return bloc;
      },
      seed: () => DriveLoaded(sampleDrives),
      act: (bloc) => bloc.add(AddDriveEvent(testDrive())),
      wait: const Duration(milliseconds: 50),
      expect: () => <DriveState>[],
      verify: (_) {
        verify(() => addDrive(any())).called(1);
        verify(() => getDrives(any())).called(1);
      },
    );

    blocTest<DriveBloc, DriveState>(
      'delete drive triggers silent reload',
      build: () {
        when(() => deleteDrive(any())).thenAnswer((_) async {});
        when(
          () => getDrives(any()),
        ).thenAnswer((_) async => [sampleDrives.first]);
        return bloc;
      },
      seed: () => DriveLoaded(sampleDrives),
      act: (bloc) => bloc.add(const DeleteDriveEvent('1')),
      wait: const Duration(milliseconds: 50),
      expect: () => [
        DriveLoaded([sampleDrives.first]),
      ],
      verify: (_) {
        verify(() => deleteDrive('1')).called(1);
      },
    );

    blocTest<DriveBloc, DriveState>(
      'emits error when load fails',
      build: () {
        when(() => getDrives(any())).thenThrow(Exception('network'));
        return bloc;
      },
      act: (bloc) => bloc.add(const LoadDrivesEvent()),
      expect: () => [isA<DriveLoading>(), isA<DriveError>()],
    );
  });
}
