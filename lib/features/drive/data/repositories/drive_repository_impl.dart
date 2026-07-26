import '../../domain/entities/drive_entity.dart';
import '../../domain/repositories/drive_repository.dart';
import '../datasources/drive_local_data_source.dart';

class DriveRepositoryImpl implements DriveRepository {
  final DriveLocalDataSource localDataSource;

  DriveRepositoryImpl(this.localDataSource);

  @override
  Future<int> addDrive(DriveEntity drive) async {
    return await localDataSource.addDrive(drive);
  }

  @override
  Future<int> deleteDrive(int id) async {
    return await localDataSource.deleteDrive(id);
  }

  @override
  Future<List<DriveEntity>> getDrives() async {
    return await localDataSource.getDrives();
  }
}
