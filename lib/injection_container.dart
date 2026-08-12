import 'package:get_it/get_it.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'core/firebase/firebase_initializer.dart';
import 'features/drive/data/datasources/drive_firestore_data_source.dart';
import 'features/drive/data/repositories/drive_repository_impl.dart';
import 'features/drive/domain/repositories/drive_repository.dart';
import 'features/drive/domain/usecases/add_drive.dart';
import 'features/drive/domain/usecases/delete_drive.dart';
import 'features/drive/domain/usecases/get_drives.dart';
import 'features/drive/domain/usecases/reschedule_alarms.dart';
import 'features/drive/domain/usecases/update_drive.dart';
import 'features/drive/presentation/bloc/drive/drive_bloc.dart';
import 'features/settings/presentation/bloc/theme/theme_bloc.dart';
import 'services/alarm_service.dart';

final sl = GetIt.instance;

Future<void> init() async {
  await FirebaseInitializer.initialize();
  await _registerDependencies();
}

Future<void> initForTesting({
  DriveRepository? driveRepository,
  DriveFirestoreDataSource? firestoreDataSource,
  AlarmScheduler? alarmServiceOverride,
  FlutterSecureStorage? secureStorage,
}) async {
  if (sl.isRegistered<DriveRepository>() || sl.isRegistered<ThemeBloc>()) {
    await sl.reset();
  }

  await _registerDependencies(
    driveRepository: driveRepository,
    firestoreDataSource: firestoreDataSource,
    alarmServiceOverride: alarmServiceOverride,
    secureStorage: secureStorage,
  );
}

Future<void> _registerDependencies({
  DriveRepository? driveRepository,
  DriveFirestoreDataSource? firestoreDataSource,
  AlarmScheduler? alarmServiceOverride,
  FlutterSecureStorage? secureStorage,
}) async {
  sl.registerFactory(() => ThemeBloc(sl()));

  sl.registerFactory(
    () => DriveBloc(
      getDrives: sl(),
      addDrive: sl(),
      updateDrive: sl(),
      deleteDrive: sl(),
    ),
  );

  sl.registerLazySingleton(() => GetDrives(sl()));
  sl.registerLazySingleton(() => AddDrive(sl()));
  sl.registerLazySingleton(() => UpdateDrive(sl()));
  sl.registerLazySingleton(() => DeleteDrive(sl()));
  sl.registerLazySingleton(() => RescheduleAlarms(sl()));

  if (!sl.isRegistered<AlarmScheduler>()) {
    sl.registerLazySingleton<AlarmScheduler>(
      () => alarmServiceOverride ?? alarmService,
    );
  }

  if (firestoreDataSource != null) {
    sl.registerLazySingleton<DriveFirestoreDataSource>(() => firestoreDataSource);
  } else if (!sl.isRegistered<DriveFirestoreDataSource>()) {
    sl.registerLazySingleton<DriveFirestoreDataSource>(
      () => DriveFirestoreDataSourceImpl(sl()),
    );
  }

  if (!sl.isRegistered<FirebaseFirestore>()) {
    sl.registerLazySingleton(() => FirebaseFirestore.instance);
  }

  if (driveRepository != null) {
    sl.registerLazySingleton<DriveRepository>(() => driveRepository);
  } else {
    sl.registerLazySingleton<DriveRepository>(
      () => DriveRepositoryImpl(
        firestoreDataSource: sl(),
        alarmService: sl(),
      ),
    );
  }

  sl.registerLazySingleton<FlutterSecureStorage>(
    () => secureStorage ?? const FlutterSecureStorage(),
  );
}

Future<void> bootstrapData() async {
  final repository = sl<DriveRepository>();
  await repository.getDrives();
  await repository.rescheduleAllAlarms();
}
