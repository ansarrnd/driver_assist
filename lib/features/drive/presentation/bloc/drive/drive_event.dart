import 'package:equatable/equatable.dart';
import '../../../domain/entities/drive_entity.dart';

abstract class DriveEvent extends Equatable {
  const DriveEvent();

  @override
  List<Object> get props => [];
}

class LoadDrivesEvent extends DriveEvent {
  final bool silent;

  const LoadDrivesEvent({this.silent = false});

  @override
  List<Object> get props => [silent];
}

class AddDriveEvent extends DriveEvent {
  final DriveEntity drive;

  const AddDriveEvent(this.drive);

  @override
  List<Object> get props => [drive];
}

class UpdateDriveEvent extends DriveEvent {
  final DriveEntity drive;

  const UpdateDriveEvent(this.drive);

  @override
  List<Object> get props => [drive];
}

class DeleteDriveEvent extends DriveEvent {
  final String id;

  const DeleteDriveEvent(this.id);

  @override
  List<Object> get props => [id];
}
