import 'package:get_it/get_it.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'core/database/database_helper.dart';
import 'features/drive/data/datasources/drive_local_data_source.dart';
import 'features/drive/data/repositories/drive_repository_impl.dart';
import 'features/drive/domain/repositories/drive_repository.dart';
import 'features/drive/domain/usecases/add_drive.dart';
import 'features/drive/domain/usecases/delete_drive.dart';
import 'features/drive/domain/usecases/get_drives.dart';
import 'features/drive/presentation/bloc/drive/drive_bloc.dart';
import 'features/settings/presentation/bloc/theme/theme_bloc.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // Features - Settings
  // Bloc
  sl.registerFactory(() => ThemeBloc(sl()));

  // Features - Drive
  // Bloc
  sl.registerFactory(
    () => DriveBloc(
      getDrives: sl(),
      addDrive: sl(),
      deleteDrive: sl(),
    ),
  );

  // Use cases
  sl.registerLazySingleton(() => GetDrives(sl()));
  sl.registerLazySingleton(() => AddDrive(sl()));
  sl.registerLazySingleton(() => DeleteDrive(sl()));

  // Repository
  sl.registerLazySingleton<DriveRepository>(
    () => DriveRepositoryImpl(sl()),
  );

  // Data sources
  sl.registerLazySingleton<DriveLocalDataSource>(
    () => DriveLocalDataSourceImpl(sl()),
  );

  // Core
  sl.registerLazySingleton(() => DatabaseHelper.instance);

  // External
  sl.registerLazySingleton(() => const FlutterSecureStorage());
}
