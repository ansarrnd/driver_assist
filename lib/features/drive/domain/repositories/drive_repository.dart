import '../entities/drive_entity.dart';

abstract class DriveRepository {
  Future<List<DriveEntity>> getDrives();
  Future<int> addDrive(DriveEntity drive);
  Future<int> deleteDrive(int id);
}
