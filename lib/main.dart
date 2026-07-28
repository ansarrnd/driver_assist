import 'package:flutter/material.dart';
import 'dart:io';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'services/notification_service.dart';
import 'services/alarm_service.dart';
import 'core/routes/app_router.dart';
import 'injection_container.dart' as di;
import 'features/settings/presentation/bloc/theme/theme_bloc.dart';
import 'features/settings/presentation/bloc/theme/theme_event.dart';
import 'features/settings/presentation/bloc/theme/theme_state.dart';
import 'features/drive/presentation/bloc/drive/drive_bloc.dart';
import 'features/drive/presentation/bloc/drive/drive_event.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  tz.initializeTimeZones();
  await notificationService.init();
  await notificationService.requestPermissions();
  await alarmService.init();
  
  await di.init();
  
  final prefs = await SharedPreferences.getInstance();
  final hasSeenOnboarding = prefs.getBool('has_seen_onboarding') ?? false;
  
  AppRouter.initialize(hasSeenOnboarding);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<ThemeBloc>(
          create: (_) => di.sl<ThemeBloc>()..add(LoadThemeEvent()),
        ),
        BlocProvider<DriveBloc>(
          create: (_) => di.sl<DriveBloc>()..add(LoadDrivesEvent()),
        ),
      ],
      child: BlocBuilder<ThemeBloc, ThemeState>(
        builder: (context, state) {
          return MaterialApp.router(
            title: 'Driver Schedule',
            theme: state.themeData,
            routerConfig: AppRouter.router,
          );
        },
      ),
    );
  }
}
