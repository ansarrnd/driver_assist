import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/usecases/usecase.dart';
import '../../../domain/usecases/add_drive.dart';
import '../../../domain/usecases/delete_drive.dart';
import '../../../domain/usecases/get_drives.dart';
import 'drive_event.dart';
import 'drive_state.dart';

class DriveBloc extends Bloc<DriveEvent, DriveState> {
  final GetDrives getDrives;
  final AddDrive addDrive;
  final DeleteDrive deleteDrive;

  DriveBloc({
    required this.getDrives,
    required this.addDrive,
    required this.deleteDrive,
  }) : super(DriveInitial()) {
    on<LoadDrivesEvent>(_onLoadDrives);
    on<AddDriveEvent>(_onAddDrive);
    on<DeleteDriveEvent>(_onDeleteDrive);
  }

  Future<void> _onLoadDrives(LoadDrivesEvent event, Emitter<DriveState> emit) async {
    emit(DriveLoading());
    try {
      final drives = await getDrives(NoParams());
      emit(DriveLoaded(drives));
    } catch (e) {
      emit(DriveError(e.toString()));
    }
  }

  Future<void> _onAddDrive(AddDriveEvent event, Emitter<DriveState> emit) async {
    try {
      await addDrive(event.drive);
      add(LoadDrivesEvent());
    } catch (e) {
      emit(DriveError(e.toString()));
    }
  }

  Future<void> _onDeleteDrive(DeleteDriveEvent event, Emitter<DriveState> emit) async {
    try {
      await deleteDrive(event.id);
      add(LoadDrivesEvent());
    } catch (e) {
      emit(DriveError(e.toString()));
    }
  }
}
