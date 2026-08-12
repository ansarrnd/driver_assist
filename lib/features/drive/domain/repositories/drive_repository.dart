import '../entities/drive_entity.dart';

abstract class DriveRepository {
  Future<List<DriveEntity>> getDrives();
  Future<String> addDrive(DriveEntity drive);
  Future<void> updateDrive(DriveEntity drive);
  Future<void> deleteDrive(String id);
  Future<void> rescheduleAllAlarms();
}
