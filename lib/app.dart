import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/routes/app_router.dart';
import 'features/drive/presentation/bloc/drive/drive_bloc.dart';
import 'features/drive/presentation/bloc/drive/drive_event.dart';
import 'features/settings/presentation/bloc/theme/theme_bloc.dart';
import 'features/settings/presentation/bloc/theme/theme_event.dart';
import 'features/settings/presentation/bloc/theme/theme_state.dart';

class DriverScheduleRoot extends StatefulWidget {
  final ThemeBloc themeBloc;
  final DriveBloc driveBloc;
  final bool loadDrivesOnStart;

  const DriverScheduleRoot({
    super.key,
    required this.themeBloc,
    required this.driveBloc,
    this.loadDrivesOnStart = true,
  });

  @override
  State<DriverScheduleRoot> createState() => _DriverScheduleRootState();
}

class _DriverScheduleRootState extends State<DriverScheduleRoot> {
  @override
  void initState() {
    super.initState();
    widget.themeBloc.add(LoadThemeEvent());
    if (widget.loadDrivesOnStart) {
      widget.driveBloc.add(const LoadDrivesEvent());
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<ThemeBloc>.value(value: widget.themeBloc),
        BlocProvider<DriveBloc>.value(value: widget.driveBloc),
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
