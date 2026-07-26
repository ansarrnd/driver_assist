import 'package:equatable/equatable.dart';
import '../../../domain/entities/drive_entity.dart';

abstract class DriveEvent extends Equatable {
  const DriveEvent();

  @override
  List<Object> get props => [];
}

class LoadDrivesEvent extends DriveEvent {}

class AddDriveEvent extends DriveEvent {
  final DriveEntity drive;
  const AddDriveEvent(this.drive);

  @override
  List<Object> get props => [drive];
}

class DeleteDriveEvent extends DriveEvent {
  final int id;
  const DeleteDriveEvent(this.id);

  @override
  List<Object> get props => [id];
}
