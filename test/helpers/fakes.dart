import 'package:driver_schedule/features/drive/domain/entities/drive_entity.dart';
import 'package:driver_schedule/features/drive/domain/entities/drive_type.dart';
import 'package:driver_schedule/features/drive/domain/repositories/drive_repository.dart';
import 'package:driver_schedule/services/alarm_service.dart';

class FakeAlarmService implements AlarmScheduler {
  final List<DriveEntity> scheduled = [];
  final List<String> cancelled = [];

  @override
  Future<void> scheduleDriveAlarm(DriveEntity entry) async {
    scheduled.removeWhere((drive) => drive.id == entry.id);
    scheduled.add(entry);
  }

  @override
  Future<void> cancelAlarm(String entryId) async {
    cancelled.add(entryId);
    scheduled.removeWhere((drive) => drive.id == entryId);
  }

  @override
  Future<void> rescheduleAll(List<DriveEntity> drives) async {
    scheduled
      ..clear()
      ..addAll(drives);
  }
}

class InMemoryDriveRepository implements DriveRepository {
  final Map<String, DriveEntity> _entries = {};
  int _idCounter = 0;
  final FakeAlarmService alarmService;

  InMemoryDriveRepository({FakeAlarmService? alarmService})
      : alarmService = alarmService ?? FakeAlarmService();

  @override
  Future<String> addDrive(DriveEntity drive) async {
    final id = drive.id ?? 'test-${++_idCounter}';
    final saved = drive.copyWith(id: id);
    _entries[id] = saved;
    await alarmService.scheduleDriveAlarm(saved);
    return id;
  }

  @override
  Future<void> deleteDrive(String id) async {
    _entries.remove(id);
    await alarmService.cancelAlarm(id);
  }

  @override
  Future<List<DriveEntity>> getDrives() async {
    final drives = _entries.values.toList()
      ..sort((a, b) => b.dateTime.compareTo(a.dateTime));
    return drives;
  }

  @override
  Future<void> rescheduleAllAlarms() async {
    await alarmService.rescheduleAll(_entries.values.toList());
  }

  @override
  Future<void> updateDrive(DriveEntity drive) async {
    if (drive.id == null) {
      throw StateError('Cannot update drive without id');
    }
    _entries[drive.id!] = drive;
    await alarmService.scheduleDriveAlarm(drive);
  }

  void seed(DriveEntity drive) {
    final id = drive.id ?? 'seed-${++_idCounter}';
    _entries[id] = drive.copyWith(id: id);
  }
}

DriveEntity testDrive({
  String? id,
  String customerName = 'Test Customer',
  String source = 'Pickup Point',
  String destination = 'Drop Point',
  DateTime? dateTime,
  DriveType type = DriveType.trip,
  int? alarmOffsetMinutes = 60,
}) {
  return DriveEntity(
    id: id,
    customerName: customerName,
    source: source,
    destination: destination,
    dateTime: dateTime ?? DateTime(2026, 8, 15, 9, 30),
    type: type,
    alarmOffsetMinutes: alarmOffsetMinutes,
  );
}
