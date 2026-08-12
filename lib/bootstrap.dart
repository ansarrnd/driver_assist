import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;

import 'app.dart';
import 'core/routes/app_router.dart';
import 'features/drive/domain/repositories/drive_repository.dart';
import 'features/drive/presentation/bloc/drive/drive_bloc.dart';
import 'features/settings/presentation/bloc/theme/theme_bloc.dart';
import 'injection_container.dart' as di;
import 'services/alarm_service.dart';
import 'services/notification_service.dart';

class AppBootstrapConfig {
  final bool initializeFirebase;
  final bool initializeNotifications;
  final bool initializeAlarms;
  final bool requestNotificationPermissions;
  final bool bootstrapData;
  final bool? hasSeenOnboarding;
  final DriveRepository? testDriveRepository;

  const AppBootstrapConfig({
    this.initializeFirebase = true,
    this.initializeNotifications = true,
    this.initializeAlarms = true,
    this.requestNotificationPermissions = true,
    this.bootstrapData = true,
    this.hasSeenOnboarding,
    this.testDriveRepository,
  });

  const AppBootstrapConfig.testing({
    this.hasSeenOnboarding = true,
    this.testDriveRepository,
  })  : initializeFirebase = false,
        initializeNotifications = false,
        initializeAlarms = false,
        requestNotificationPermissions = false,
        bootstrapData = false;
}

Future<bool> resolveOnboardingFlag(AppBootstrapConfig config) async {
  if (config.hasSeenOnboarding != null) {
    return config.hasSeenOnboarding!;
  }

  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool('has_seen_onboarding') ?? false;
}

Future<void> bootstrapApp(AppBootstrapConfig config) async {
  WidgetsFlutterBinding.ensureInitialized();
  tz.initializeTimeZones();

  if (config.initializeNotifications) {
    await notificationService.init();
    if (config.requestNotificationPermissions) {
      await notificationService.requestPermissions();
    }
  }

  if (config.initializeAlarms) {
    await alarmService.init();
  }

  if (config.initializeFirebase) {
    await di.init();
    if (config.bootstrapData) {
      await di.bootstrapData();
    }
  } else {
    await di.initForTesting(driveRepository: config.testDriveRepository);
  }

  final hasSeenOnboarding = await resolveOnboardingFlag(config);
  AppRouter.initialize(hasSeenOnboarding);
}

Future<void> runDriverScheduleApp({
  AppBootstrapConfig config = const AppBootstrapConfig(),
  bool loadDrivesOnStart = true,
}) async {
  await bootstrapApp(config);
  runApp(
    DriverScheduleRoot(
      themeBloc: di.sl<ThemeBloc>(),
      driveBloc: di.sl<DriveBloc>(),
      loadDrivesOnStart: loadDrivesOnStart,
    ),
  );
}
