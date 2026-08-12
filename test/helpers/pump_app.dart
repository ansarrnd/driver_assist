import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:driver_schedule/core/theme/theme.dart';
import 'package:driver_schedule/features/drive/presentation/bloc/drive/drive_bloc.dart';
import 'package:driver_schedule/features/settings/presentation/bloc/theme/theme_bloc.dart';

Future<void> configureTestEnvironment() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;
}

ThemeData testTheme() {
  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFFE50E2F),
      brightness: Brightness.dark,
    ),
    scaffoldBackgroundColor: const Color(0xFF1A1A1A),
    extensions: const [
      AppThemeExtension(
        backgroundDecoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1A1A1A), Color(0xFF8B0000)],
          ),
        ),
      ),
    ],
  );
}

Widget buildTestApp({
  required Widget child,
  DriveBloc? driveBloc,
  ThemeBloc? themeBloc,
  ThemeData? theme,
  bool wrapInScaffold = true,
}) {
  final resolvedTheme = theme ?? testTheme();
  final body = wrapInScaffold ? Scaffold(body: child) : child;
  final app = MaterialApp(
    theme: resolvedTheme,
    home: body,
  );

  final providers = <BlocProvider>[
    if (themeBloc != null) BlocProvider<ThemeBloc>.value(value: themeBloc),
    if (driveBloc != null) BlocProvider<DriveBloc>.value(value: driveBloc),
  ];

  if (providers.isEmpty) {
    return app;
  }

  return MultiBlocProvider(
    providers: providers,
    child: app,
  );
}

Future<void> pumpTestWidget(
  WidgetTester tester,
  Widget child, {
  DriveBloc? driveBloc,
  ThemeBloc? themeBloc,
  ThemeData? theme,
  bool wrapInScaffold = true,
}) async {
  await tester.pumpWidget(
    buildTestApp(
      child: child,
      driveBloc: driveBloc,
      themeBloc: themeBloc,
      theme: theme,
      wrapInScaffold: wrapInScaffold,
    ),
  );
  await tester.pump();
}
