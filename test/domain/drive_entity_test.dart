import 'package:flutter_test/flutter_test.dart';

import 'package:driver_schedule/features/drive/domain/entities/drive_entity.dart';
import 'package:driver_schedule/features/drive/domain/entities/drive_type.dart';
import 'package:driver_schedule/features/drive/domain/utils/drive_schedule_filter.dart';
import 'package:driver_schedule/services/alarm_service.dart';

import '../helpers/fakes.dart';

void main() {
  group('DriveEntity', () {
    test('serializes to and from Firestore', () {
      final entity = testDrive(id: 'doc-1');
      final firestore = entity.toFirestore();
      final restored = DriveEntity.fromFirestore('doc-1', firestore);

      expect(restored.id, 'doc-1');
      expect(restored.customerName, entity.customerName);
      expect(restored.source, entity.source);
      expect(restored.destination, entity.destination);
      expect(restored.dateTime, entity.dateTime);
      expect(restored.type, DriveType.trip);
      expect(restored.alarmOffsetMinutes, 60);
    });
  });

  group('DriveType', () {
    test('fromString parses trip and ticket', () {
      expect(DriveType.fromString('trip'), DriveType.trip);
      expect(DriveType.fromString('ticket'), DriveType.ticket);
      expect(DriveType.fromString('unknown'), DriveType.trip);
    });
  });

  group('filterDriveEntries', () {
    final reference = DateTime(2026, 8, 12, 12);

    test('filters by type and month', () {
      final entries = [
        testDrive(
          id: '1',
          dateTime: DateTime(2026, 8, 10, 9),
          type: DriveType.trip,
        ),
        testDrive(
          id: '2',
          dateTime: DateTime(2026, 8, 20, 9),
          type: DriveType.ticket,
        ),
        testDrive(
          id: '3',
          dateTime: DateTime(2026, 9, 1, 9),
          type: DriveType.trip,
        ),
      ];

      final tripsThisMonth = filterDriveEntries(
        entries: entries,
        type: DriveType.trip,
        period: DriveSchedulePeriod.month,
        referenceTime: reference,
      );

      expect(tripsThisMonth, hasLength(1));
      expect(tripsThisMonth.first.id, '1');
    });

    test('filters today only', () {
      final entries = [
        testDrive(id: '1', dateTime: DateTime(2026, 8, 12, 8)),
        testDrive(id: '2', dateTime: DateTime(2026, 8, 13, 8)),
      ];

      final todayEntries = filterDriveEntries(
        entries: entries,
        type: DriveType.trip,
        period: DriveSchedulePeriod.today,
        referenceTime: reference,
      );

      expect(todayEntries, hasLength(1));
      expect(todayEntries.first.id, '1');
    });
  });

  group('AlarmService', () {
    test('alarmIdForEntry is stable for the same id', () {
      final service = AlarmService();
      expect(
        service.alarmIdForEntry('abc123'),
        service.alarmIdForEntry('abc123'),
      );
    });
  });

  group('InMemoryDriveRepository', () {
    test('add schedules alarm after id is assigned', () async {
      final alarmService = FakeAlarmService();
      final repository = InMemoryDriveRepository(alarmService: alarmService);

      final id = await repository.addDrive(testDrive());
      expect(id, isNotEmpty);
      expect(alarmService.scheduled, hasLength(1));
      expect(alarmService.scheduled.first.id, id);
    });

    test('delete cancels alarm', () async {
      final alarmService = FakeAlarmService();
      final repository = InMemoryDriveRepository(alarmService: alarmService);
      final id = await repository.addDrive(testDrive());

      await repository.deleteDrive(id);

      expect(alarmService.cancelled, contains(id));
      expect(alarmService.scheduled, isEmpty);
    });
  });
}
