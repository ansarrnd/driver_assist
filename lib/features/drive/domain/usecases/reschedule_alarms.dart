import '../../../../core/usecases/usecase.dart';
import '../repositories/drive_repository.dart';

class RescheduleAlarms implements UseCase<void, NoParams> {
  final DriveRepository repository;

  RescheduleAlarms(this.repository);

  @override
  Future<void> call(NoParams params) async {
    return repository.rescheduleAllAlarms();
  }
}
