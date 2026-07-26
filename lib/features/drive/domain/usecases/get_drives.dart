import '../../../../core/usecases/usecase.dart';
import '../entities/drive_entity.dart';
import '../repositories/drive_repository.dart';

class GetDrives implements UseCase<List<DriveEntity>, NoParams> {
  final DriveRepository repository;

  GetDrives(this.repository);

  @override
  Future<List<DriveEntity>> call(NoParams params) async {
    return await repository.getDrives();
  }
}
