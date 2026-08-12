import 'package:flutter_test/flutter_test.dart';

import 'package:driver_schedule/features/drive/data/datasources/drive_firestore_data_source.dart';
import 'package:driver_schedule/features/drive/data/repositories/drive_repository_impl.dart';
import 'package:driver_schedule/features/drive/domain/entities/drive_entity.dart';

import '../helpers/fakes.dart';

class FakeFirestoreDataSource implements DriveFirestoreDataSource {
  final Map<String, DriveEntity> entries = {};
  bool seedCalled = false;

  @override
  Future<String> addDrive(DriveEntity drive) async {
    final id = drive.id ?? 'generated-${entries.length + 1}';
    entries[id] = drive.copyWith(id: id);
    return id;
  }

  @override
  Future<void> deleteDrive(String id) async {
    entries.remove(id);
  }

  @override
  Future<List<DriveEntity>> getDrives() async {
    return entries.values.toList()
      ..sort((a, b) => b.dateTime.compareTo(a.dateTime));
  }

  @override
  Future<void> seedMockDataIfEmpty() async {
    seedCalled = true;
  }

  @override
  Future<void> updateDrive(DriveEntity drive) async {
    if (drive.id == null) {
      throw StateError('missing id');
    }
    entries[drive.id!] = drive;
  }
}

void main() {
  group('DriveRepositoryImpl', () {
    late FakeFirestoreDataSource dataSource;
    late FakeAlarmService alarmService;
    late DriveRepositoryImpl repository;

    setUp(() {
      dataSource = FakeFirestoreDataSource();
      alarmService = FakeAlarmService();
      repository = DriveRepositoryImpl(
        firestoreDataSource: dataSource,
        alarmService: alarmService,
      );
    });

    test('getDrives seeds when collection is empty', () async {
      await repository.getDrives();
      expect(dataSource.seedCalled, isTrue);
    });

    test('addDrive persists then schedules alarm with generated id', () async {
      final id = await repository.addDrive(testDrive());

      expect(id, isNotEmpty);
      expect(alarmService.scheduled, hasLength(1));
      expect(alarmService.scheduled.first.id, id);
    });

    test('updateDrive reschedules alarm', () async {
      final id = await repository.addDrive(testDrive());
      alarmService.scheduled.clear();

      await repository.updateDrive(testDrive(id: id, alarmOffsetMinutes: 15));

      expect(alarmService.scheduled.single.alarmOffsetMinutes, 15);
    });

    test('deleteDrive cancels alarm', () async {
      final id = await repository.addDrive(testDrive());

      await repository.deleteDrive(id);

      expect(alarmService.cancelled, contains(id));
    });

    test('rescheduleAllAlarms schedules each drive', () async {
      dataSource.entries['1'] = testDrive(id: '1');
      dataSource.entries['2'] = testDrive(id: '2', customerName: 'Second');

      await repository.rescheduleAllAlarms();

      expect(alarmService.scheduled, hasLength(2));
    });
  });
}
