import 'package:equatable/equatable.dart';
import '../../../domain/entities/drive_entity.dart';

abstract class DriveState extends Equatable {
  const DriveState();

  @override
  List<Object> get props => [];
}

class DriveInitial extends DriveState {}

class DriveLoading extends DriveState {}

class DriveLoaded extends DriveState {
  final List<DriveEntity> drives;

  const DriveLoaded(this.drives);

  @override
  List<Object> get props => [drives];
}

class DriveError extends DriveState {
  final String message;

  const DriveError(this.message);

  @override
  List<Object> get props => [message];
}
