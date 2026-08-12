import '../../domain/entities/drive_entity.dart';
import '../../domain/repositories/drive_repository.dart';
import '../datasources/drive_firestore_data_source.dart';
import '../../../../services/alarm_service.dart';

class DriveRepositoryImpl implements DriveRepository {
  final DriveFirestoreDataSource firestoreDataSource;
  final AlarmScheduler alarmService;

  DriveRepositoryImpl({
    required this.firestoreDataSource,
    required this.alarmService,
  });

  @override
  Future<List<DriveEntity>> getDrives() async {
    await firestoreDataSource.seedMockDataIfEmpty();
    return firestoreDataSource.getDrives();
  }

  @override
  Future<String> addDrive(DriveEntity drive) async {
    final id = await firestoreDataSource.addDrive(drive);
    final savedDrive = drive.copyWith(id: id);
    await alarmService.scheduleDriveAlarm(savedDrive);
    return id;
  }

  @override
  Future<void> updateDrive(DriveEntity drive) async {
    await firestoreDataSource.updateDrive(drive);
    await alarmService.scheduleDriveAlarm(drive);
  }

  @override
  Future<void> deleteDrive(String id) async {
    await firestoreDataSource.deleteDrive(id);
    await alarmService.cancelAlarm(id);
  }

  @override
  Future<void> rescheduleAllAlarms() async {
    final drives = await firestoreDataSource.getDrives();
    for (final drive in drives) {
      await alarmService.scheduleDriveAlarm(drive);
    }
  }
}
