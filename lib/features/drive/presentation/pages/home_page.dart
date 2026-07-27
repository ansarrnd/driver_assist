import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/theme.dart';
import '../../../settings/presentation/bloc/theme/theme_bloc.dart';
import '../../../settings/presentation/bloc/theme/theme_state.dart';
import 'drive_schedule_screen.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeBloc, ThemeState>(
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Drive Schedule'),
            backgroundColor: Theme.of(context).colorScheme.inversePrimary,
            bottom: TabBar(
              controller: _tabController,
              tabs: const <Widget>[
                Tab(text: 'Trips'),
                Tab(text: 'Tickets'),
              ],
            ),
          ),
          body: Container(
            decoration: Theme.of(context).extension<AppThemeExtension>()?.backgroundDecoration ?? AppTheme.rcbBackgroundDecoration,
            child: TabBarView(
              controller: _tabController,
              children: const <Widget>[
                DriveScheduleScreen(filterType: 'trip'),
                DriveScheduleScreen(filterType: 'ticket'),
              ],
            ),
          ),
        );
      },
    );
  }
}
