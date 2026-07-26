import '../../../../core/usecases/usecase.dart';
import '../entities/drive_entity.dart';
import '../repositories/drive_repository.dart';

class AddDrive implements UseCase<int, DriveEntity> {
  final DriveRepository repository;

  AddDrive(this.repository);

  @override
  Future<int> call(DriveEntity params) async {
    return await repository.addDrive(params);
  }
}
