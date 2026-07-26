import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme.dart';
import 'drive_schedule_screen.dart';
import '../tickets_screen.dart';
import 'add_screen.dart';
import 'settings_screen.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with SingleTickerProviderStateMixin {
  int _selectedIndex = 0; // To keep track of the selected tab index
  late TabController _driveScheduleTabController;

  // _widgetOptions will now hold widgets for bottom nav items *other* than the first one.
  // The first item (Drive Schedule with tabs) is handled directly in the body.
  static const List<Widget> _widgetOptions = <Widget>[
    SizedBox.shrink(), // Placeholder for index 0, which is handled by TabBarView
    AddScreen(),
    SettingsScreen(),
  ];

  // List of titles for the AppBar corresponding to each tab
  static const List<String> _appBarTitles = <String>[
    'Drive Schedule',
    'Add Item', // You can customize this title
    'Settings',
  ];

  @override
  void initState() {
    super.initState();
    _driveScheduleTabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _driveScheduleTabController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    HapticFeedback.lightImpact();
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // Dynamically set the title based on the selected tab
        title: Text(_appBarTitles[_selectedIndex]),
        bottom: _selectedIndex == 0
            ? TabBar(
                controller: _driveScheduleTabController,
                tabs: const <Widget>[
                  Tab(text: 'Trips'),
                  Tab(text: 'Tickets'),
                ],
              )
            : null,
      ),
      body: Container(
        decoration: Theme.of(context).extension<AppThemeExtension>()?.backgroundDecoration ?? AppTheme.rcbBackgroundDecoration,
        child: Center(
          // Display the widget from _widgetOptions based on the selected index
          child: _selectedIndex == 0
              ? TabBarView(
                  controller: _driveScheduleTabController,
                  children: <Widget>[
                    const DriveScheduleScreen(), // Content for "Trips" tab
                    const TicketsScreen(),       // Content for "Tickets" tab
                  ],
                )
              : _widgetOptions.elementAt(_selectedIndex),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.drive_eta),
            label: 'Drive Schedule',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle_outline),
            label: 'Add',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.deepPurple, // Or your theme's primary color
        onTap: _onItemTapped,
      ),
    );
  }
}
