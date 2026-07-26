import '../../../../core/usecases/usecase.dart';
import '../repositories/drive_repository.dart';

class DeleteDrive implements UseCase<int, int> {
  final DriveRepository repository;

  DeleteDrive(this.repository);

  @override
  Future<int> call(int params) async {
    return await repository.deleteDrive(params);
  }
}
