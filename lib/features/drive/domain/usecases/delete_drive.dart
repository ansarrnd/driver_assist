import '../../../../core/usecases/usecase.dart';
import '../repositories/drive_repository.dart';

class DeleteDrive implements UseCase<void, String> {
  final DriveRepository repository;

  DeleteDrive(this.repository);

  @override
  Future<void> call(String params) async {
    return repository.deleteDrive(params);
  }
}
