import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:driver_schedule/core/theme/theme.dart';
import 'package:driver_schedule/features/drive/presentation/bloc/drive/drive_bloc.dart';

Future<void> configureTestEnvironment() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;
}

Widget buildTestApp({
  required Widget child,
  DriveBloc? driveBloc,
  ThemeData theme = AppTheme.rcbTheme,
}) {
  if (driveBloc != null) {
    return BlocProvider<DriveBloc>.value(
      value: driveBloc,
      child: MaterialApp(
        theme: theme,
        home: child,
      ),
    );
  }

  return MaterialApp(
    theme: theme,
    home: child,
  );
}

Future<void> pumpTestWidget(
  WidgetTester tester,
  Widget child, {
  DriveBloc? driveBloc,
  ThemeData theme = AppTheme.rcbTheme,
}) async {
  await tester.pumpWidget(
    buildTestApp(child: child, driveBloc: driveBloc, theme: theme),
  );
  await tester.pump();
}
