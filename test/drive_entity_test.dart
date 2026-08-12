import 'package:flutter_test/flutter_test.dart';

import 'package:driver_schedule/features/drive/domain/entities/drive_type.dart';
import 'package:driver_schedule/services/alarm_service.dart';

void main() {
  group('DriveType', () {
    test('fromString parses trip and ticket', () {
      expect(DriveType.fromString('trip'), DriveType.trip);
      expect(DriveType.fromString('ticket'), DriveType.ticket);
      expect(DriveType.fromString('unknown'), DriveType.trip);
    });
  });

  group('AlarmService', () {
    test('alarmIdForEntry is stable for the same id', () {
      final service = AlarmService();
      expect(service.alarmIdForEntry('abc123'), service.alarmIdForEntry('abc123'));
    });
  });
}
