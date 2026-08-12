import '../../../../core/usecases/usecase.dart';
import '../entities/drive_entity.dart';
import '../repositories/drive_repository.dart';

class UpdateDrive implements UseCase<void, DriveEntity> {
  final DriveRepository repository;

  UpdateDrive(this.repository);

  @override
  Future<void> call(DriveEntity params) async {
    return repository.updateDrive(params);
  }
}
