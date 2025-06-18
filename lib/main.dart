import 'package:flutter/material.dart';
import 'dart:io'; // Import the full dart:io library
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'database_helper.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'tickets_screen.dart'; // Import the new TicketsScreen

class NotificationService {
  static final NotificationService _notificationService = NotificationService._internal();

  factory NotificationService() {
    return _notificationService;
  }

  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher'); // default icon

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    tz.initializeTimeZones();
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  Future<void> requestPermissions() async {
    if (Platform.isIOS) {
      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    } else if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      // Request exact alarm permission for Android 12+
      await androidImplementation?.requestNotificationsPermission(); // Request basic notification permission
      await androidImplementation?.requestExactAlarmsPermission(); // Request exact alarm permission
    }
  }

  Future<void> scheduleDriveNotification(DriveEntry entry) async {
    if (entry.id == null) {
      print('Error: DriveEntry ID is null. Cannot schedule notification.');
      return;
    }
    final int notificationId = int.tryParse(entry.id!) ?? entry.hashCode;
    final tz.TZDateTime scheduledTime =
        tz.TZDateTime.from(entry.dateTime.subtract(const Duration(hours: 1)), tz.local);

    if (scheduledTime.isBefore(tz.TZDateTime.now(tz.local))) {
      print('Notification time for entry ${entry.id} is in the past. Not scheduling.');
      return;
    }

    const AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
      'drive_schedule_channel_id', // Unique channel ID
      'Drive Schedule Notifications', // Channel name
      channelDescription: 'Notifications for upcoming drives',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
    );
    const NotificationDetails notificationDetails =
        NotificationDetails(android: androidNotificationDetails);

    await flutterLocalNotificationsPlugin.zonedSchedule(
      notificationId,
      'Upcoming Drive Reminder',
      'Drive for ${entry.customerName} on ${entry.dateTime.toLocal().toString().substring(0, 10)} at ${entry.dateTime.toLocal().toString().substring(11, 16)}. From: ${entry.source} to ${entry.destination}. (In 1 hour)',
      scheduledTime,
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      payload: 'drive_entry_id_${entry.id}',
    );
    print('Scheduled notification ID $notificationId for entry ${entry.id} at $scheduledTime');
  }

  Future<void> cancelNotification(String entryIdString) async {
    final int? notificationId = int.tryParse(entryIdString);
    if (notificationId != null) {
      await flutterLocalNotificationsPlugin.cancel(notificationId);
      print('Cancelled notification for entry ID $notificationId');
    } else {
      print('Error: Could not parse entryIdString to int for cancellation: $entryIdString');
    }
  }

  Future<void> showAppOpenNotification() async {
    const AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
      'app_open_channel_id', // Unique channel ID
      'App Open Notifications', // Channel name
      channelDescription: 'Notification shown when the app is opened.',
      importance: Importance.low, // Or Importance.defaultImportance
      priority: Priority.low,
      ticker: 'ticker',
    );
    const NotificationDetails notificationDetails =
        NotificationDetails(android: androidNotificationDetails);

    await flutterLocalNotificationsPlugin.show(
      0, // Static ID for this type of notification
      'Welcome Back!',
      'Thanks for opening the Driver Schedule app.',
      notificationDetails,
      payload: 'app_open_payload',
    );
    print('App open notification shown.');
  }
}

final NotificationService notificationService = NotificationService();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Ensure bindings are initialized

  // Initialize FFI for sqflite on desktop platforms
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  await notificationService.init();
  await notificationService.requestPermissions();
  // Removed: Show a notification every time the app is opened
  // await notificationService.showAppOpenNotification();

  // Fetch all existing drive entries and schedule notifications for them
  await AndroidAlarmManager.initialize(); // Initialize AlarmManager

  try {
    final List<DriveEntry> allEntries = await DatabaseHelper.instance.getAllDriveEntries();
    for (final DriveEntry entry in allEntries) {
      // 1. Schedule 1-hour pre-notification using flutter_local_notifications
      await notificationService.scheduleDriveNotification(entry);

      // 2. Schedule AndroidAlarmManager for the actual drive time for lapsed handling
      if (entry.id != null) {
        final int? entryIntId = int.tryParse(entry.id!);
        if (entryIntId != null) {
          final int alarmId = entryIntId + _alarmManagerIdOffset;
          // Only schedule for future drives
          if (entry.dateTime.isAfter(DateTime.now())) {
            print('Scheduling AndroidAlarmManager for entry ${entry.id} at ${entry.dateTime} with alarm ID $alarmId');
            await AndroidAlarmManager.oneShotAt(
              entry.dateTime,
              alarmId,
              myCallback,
              exact: true,
              wakeup: true,
              rescheduleOnReboot: true,
            );
          } else {
            print('Skipping AndroidAlarmManager for past entry ${entry.id}');
          }
        }
      }
    }
  } catch (e) {
    print('Error fetching or scheduling notifications for DB entries: $e');
  }

  runApp(const MyApp());
}

const String LAPSED_DRIVES_GROUP_KEY = 'com.example.driver_schedule.LAPSED_DRIVES';
const int LAPSED_DRIVES_SUMMARY_NOTIFICATION_ID = -1; // A fixed ID for the summary
const int _alarmManagerIdOffset = 100000; // Offset for AndroidAlarmManager IDs

@pragma('vm:entry-point')
void myCallback(int alarmId) async { // Renamed id to alarmId and made async
  // This function runs in a background isolate.
  // Ensure Flutter bindings are initialized for this isolate.
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize timezone data for the background isolate
  tz.initializeTimeZones();
  // Set the local location (optional, if you need to schedule with specific local times here)
  // tz.setLocalLocation(tz.getLocation('your_timezone_identifier')); // e.g., 'America/New_York'

  final int originalEntryId = alarmId - _alarmManagerIdOffset;

  // Initialize DB for background isolate
  // This requires path_provider and sqflite to be available in the background isolate.
  // Ensure Application.kt has GeneratedPluginRegistrant.registerWith(it)
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  DriveEntry? entry;
  try {
    // Use DatabaseHelper.instance.database to ensure it's properly initialized
    final Database dbInstance = await DatabaseHelper.instance.database;

    final List<Map<String, dynamic>> maps = await dbInstance.query(
      DatabaseHelper.tableDriveEntries,
      where: '${DatabaseHelper.columnId} = ?',
      whereArgs: [originalEntryId],
    );
    if (maps.isNotEmpty) {
      entry = DriveEntry.fromMap(maps.first);
    }
  } catch (e) {
    print('Error accessing DB in myCallback for alarmId $alarmId (originalEntryId $originalEntryId): $e');
    return;
  } finally {
    // Do not close the singleton database instance here; DatabaseHelper manages its lifecycle.
  }

  if (entry == null) {
    print('Lapsed Alarm: Entry with original ID $originalEntryId not found in myCallback.');
    return;
  }

  // Initialize flutter_local_notifications for the background isolate.
  // Use similar initialization settings as in your main app.
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher'); // Default icon

  // For iOS, permissions are usually requested upfront.
  // These settings are for initializing the plugin instance.
  const DarwinInitializationSettings initializationSettingsIOS =
      DarwinInitializationSettings(
    requestAlertPermission: false,
    requestBadgePermission: false,
    requestSoundPermission: false,
  );

  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    iOS: initializationSettingsIOS,
  );

  // Initialize the plugin. It's good practice to await this.
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

    // Individual Lapsed Notification
    final AndroidNotificationDetails lapsedNotificationAndroidDetails =
        const AndroidNotificationDetails( // Added const
      'lapsed_drive_channel_id', 
      'Lapsed Drive Alerts',
      channelDescription: 'Alerts for drives that have reached their scheduled time.',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
      groupKey: LAPSED_DRIVES_GROUP_KEY,
    );
    final NotificationDetails lapsedNotificationDetails = // Removed const
        NotificationDetails(android: lapsedNotificationAndroidDetails);

    await flutterLocalNotificationsPlugin.show(
      originalEntryId, // Use original entry ID for this specific notification
      'Drive Time Reached: ${entry.customerName}',
      'Drive for ${entry.customerName} from ${entry.source} to ${entry.destination} was scheduled for ${entry.dateTime.toLocal().toString().substring(11, 16)}.',
      lapsedNotificationDetails,
      payload: 'lapsed_drive_${entry.id}',
    );

    // Group Summary Notification
    final List<ActiveNotification> activeGroupNotifications = [];
    final allActive = await flutterLocalNotificationsPlugin.getActiveNotifications();
    for (final activeNotification in allActive) {
      if (activeNotification.groupKey == LAPSED_DRIVES_GROUP_KEY && activeNotification.id != LAPSED_DRIVES_SUMMARY_NOTIFICATION_ID) {
          activeGroupNotifications.add(activeNotification);
      }
    }

    int totalLapsedInSummary = activeGroupNotifications.length;
    // Ensure the current one is counted if getActiveNotifications was too fast
    if (!activeGroupNotifications.any((n) => n.id == originalEntryId)) {
        totalLapsedInSummary++;
    }

    List<String> summaryLines = activeGroupNotifications
        .map((n) => n.title ?? "Lapsed Drive") // Use title from active notification
        .take(5) // Limit lines in summary
        .toList();

    // If the current notification wasn't picked up by getActiveNotifications yet,
    // and there's space, add its title to the summary lines.
    if (!activeGroupNotifications.any((n) => n.id == originalEntryId) && summaryLines.length < 5) {
        summaryLines.insert(0, 'Drive Time Reached: ${entry.customerName}'); 
    }
    
    final AndroidNotificationDetails groupSummaryAndroidDetails = // Added const
        AndroidNotificationDetails(
      'lapsed_drive_channel_id', // Can use the same channel
      'Lapsed Drive Alerts', // Channel name
      channelDescription: 'Summary of lapsed drive alerts.',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      groupKey: LAPSED_DRIVES_GROUP_KEY,
      setAsGroupSummary: true,
      styleInformation: InboxStyleInformation(
          summaryLines.isEmpty ? ['Review lapsed drives'] : summaryLines,
          contentTitle: '$totalLapsedInSummary Lapsed Drive${totalLapsedInSummary == 1 ? "" : "s"}',
          summaryText: '$totalLapsedInSummary drive(s) reached scheduled time',
      ),
    );
    final NotificationDetails groupSummaryDetails = // Removed const
        NotificationDetails(android: groupSummaryAndroidDetails);

    await flutterLocalNotificationsPlugin.show(
      LAPSED_DRIVES_SUMMARY_NOTIFICATION_ID,
      '$totalLapsedInSummary Lapsed Drive(s)',
      'You have $totalLapsedInSummary drive(s) that reached their scheduled time.',
      groupSummaryDetails,
    );

    print('Lapsed alarm callback executed for original entry ID $originalEntryId. Customer: ${entry.customerName}');
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Driver Schedule',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true, // Recommended for new Flutter projects
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}


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
      body: Center(
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

// Data model for a drive entry
class DriveEntry {
  final String customerName;
  final DateTime dateTime; // Changed from TimeOfDay to DateTime
  final String source;
  final String destination;
  final String? id; // Optional: for unique identification
  final String type; // 'trip' or 'ticket'

  DriveEntry({
    required this.customerName,
    required this.dateTime,
    required this.source,
    required this.destination,
    this.id,
    this.type = 'trip', // Default to 'trip'
  });

  // Convert a DriveEntry into a Map. Keys must correspond to column names in the database.
  Map<String, dynamic> toMap() {
    return {
      // DatabaseHelper.columnId is auto-generated for new entries,
      // but needed for updates. If id is null, it means it's a new entry.
      if (id != null) DatabaseHelper.columnId: int.tryParse(id!),
      DatabaseHelper.columnCustomerName: customerName,
      // Store DateTime as ISO8601 string
      DatabaseHelper.columnDateTime: dateTime.toIso8601String(),
      DatabaseHelper.columnSource: source,
      DatabaseHelper.columnDestination: destination,
      DatabaseHelper.columnType: type,
    };
  }

  // Create a DriveEntry from a map retrieved from the database.
  factory DriveEntry.fromMap(Map<String, dynamic> map) {
    return DriveEntry(
      id: map[DatabaseHelper.columnId]?.toString(), // SQLite ID is integer
      customerName: map[DatabaseHelper.columnCustomerName],
      dateTime: DateTime.parse(map[DatabaseHelper.columnDateTime] as String),
      source: map[DatabaseHelper.columnSource],
      destination: map[DatabaseHelper.columnDestination],
      type: map[DatabaseHelper.columnType] ?? 'trip', // Default to 'trip' if null (for old data)
    );
  }
}

// Screen to display the list of drive schedules
class DriveScheduleScreen extends StatefulWidget {
  const DriveScheduleScreen({super.key});
  @override
  State<DriveScheduleScreen> createState() => _DriveScheduleScreenState();
}

class _DriveScheduleScreenState extends State<DriveScheduleScreen> {
  // Filter options
  final List<String> _filterOptions = ['Today', 'Week', 'Month'];
  String _selectedFilter = 'Month'; // Default filter
  late Future<List<DriveEntry>> _driveEntriesFuture;

  @override
  void initState() {
    super.initState();
    _refreshDriveEntries();
  }

  void _refreshDriveEntries() {
    setState(() {
      // DriveScheduleScreen should only show 'trip' type entries
      _driveEntriesFuture = DatabaseHelper.instance.getDriveEntriesByType('trip');
    });
  }

  // This method will filter the entries fetched from the database
  List<DriveEntry> _getFilteredEntries(List<DriveEntry> allEntries) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (_selectedFilter == 'Today') {
      return allEntries.where((entry) {
        final entryDate = DateTime(entry.dateTime.year, entry.dateTime.month, entry.dateTime.day);
        return entryDate.isAtSameMomentAs(today);
      }).toList();
    } else if (_selectedFilter == 'Week') {
      // Assuming week starts on Monday (weekday 1) and ends on Sunday (weekday 7)
      final startOfWeek = today.subtract(Duration(days: today.weekday - 1));
      final endOfWeek = startOfWeek.add(const Duration(days: 6));
      return allEntries.where((entry) {
        final entryDate = DateTime(entry.dateTime.year, entry.dateTime.month, entry.dateTime.day);
        return !entryDate.isBefore(startOfWeek) && !entryDate.isAfter(endOfWeek);
      }).toList();
    } else if (_selectedFilter == 'Month') {
      return allEntries.where((entry) {
        return entry.dateTime.year == now.year && entry.dateTime.month == now.month;
      }).toList();
    }
    return allEntries; // Default fallback, though should not be reached
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: DropdownButtonFormField<String>(
            value: _selectedFilter,
            decoration: InputDecoration(
              labelText: 'Filter by',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
            ),
            items: _filterOptions.map((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
            onChanged: (String? newValue) {
              if (newValue != null) {
                setState(() {
                  _selectedFilter = newValue;
                  // Re-filtering happens in the FutureBuilder based on the new _selectedFilter
                  // No need to call _refreshDriveEntries unless you want to re-fetch from DB on filter change
                });
              }
            },
          ),
        ),
        Expanded(
          child: FutureBuilder<List<DriveEntry>>(
            future: _driveEntriesFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(
                  child: Text(
                    'No drive schedules available.',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                );
              } else {
                final allEntries = snapshot.data!;
                final displayedEntries = _getFilteredEntries(allEntries);

                if (displayedEntries.isEmpty && allEntries.isNotEmpty) {
                  // This means filtering resulted in an empty list, but there is data
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        'No drive schedules found for "$_selectedFilter".',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                    )
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(8.0, 0, 8.0, 8.0),
                  itemCount: displayedEntries.length,
                  itemBuilder: (context, index) {
                    final entry = displayedEntries[index];
                    return InkWell( // Keep InkWell for potential future taps or just for the ripple effect
                      child: Card(
                        elevation: 4.0,
                        margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                entry.customerName,
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8.0),
                              _buildInfoRow(context, Icons.access_time, 'Date & Time: ${entry.dateTime.toLocal().toString().substring(0, 16)}'),
                              const SizedBox(height: 4.0),
                              _buildInfoRow(context, Icons.location_on_outlined, 'From: ${entry.source}'),
                              const SizedBox(height: 4.0),
                              _buildInfoRow(context, Icons.flag_outlined, 'To: ${entry.destination}'),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              }
            },
          ),
        ),
      ],
    );
  }
}

Widget _buildInfoRow(BuildContext context, IconData icon, String text) {
  return Row(
    children: <Widget>[
      Icon(icon, size: 18.0, color: Theme.of(context).colorScheme.primary),
      const SizedBox(width: 8.0),
      Expanded(
        child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
      ),
    ],
  );
}



// Placeholder screen for Add
// This screen can now also be used for editing an existing entry.
class AddScreen extends StatefulWidget {
  final DriveEntry? entryToEdit; // If null, it's "Add" mode. Otherwise, "Edit" mode.

  const AddScreen({super.key, this.entryToEdit});

 @override
  State<AddScreen> createState() => _AddScreenState();
}

class _AddScreenState extends State<AddScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _customerNameController = TextEditingController();
  final TextEditingController _dateController = TextEditingController(); // For Date
  final TextEditingController _timeController = TextEditingController();
  final TextEditingController _sourceController = TextEditingController();
  final TextEditingController _destinationController = TextEditingController();
  String _selectedType = 'trip'; // Default to 'trip'

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  bool get _isEditMode => widget.entryToEdit != null;

  @override
  void initState() {
    super.initState();
    if (_isEditMode) {
      final entry = widget.entryToEdit!;
      _customerNameController.text = entry.customerName;
      _selectedDate = entry.dateTime;
      _selectedTime = TimeOfDay.fromDateTime(entry.dateTime);
      _dateController.text = "${_selectedDate!.toLocal()}".split(' ')[0]; // Format as YYYY-MM-DD
      _timeController.text = _selectedTime!.format(context); // Format for display
      _sourceController.text = entry.source;
      _selectedType = entry.type; // Initialize type for edit mode
      _destinationController.text = entry.destination;
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = "${picked.toLocal()}".split(' ')[0]; // Format as YYYY-MM-DD
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
        _timeController.text = picked.format(context); // Format the time for the text field
      });
    }
  }

  void _submitForm() async { // Make the method async
    if (_formKey.currentState!.validate()) {
      // Process the data
      String customerName = _customerNameController.text;
      String source = _sourceController.text;
      String destination = _destinationController.text;

      if (_selectedDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a date.')),
        );
        return;
      }
      if (_selectedTime == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a time.')),
        );
        return;
      }

      final DateTime combinedDateTime = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );

      if (_isEditMode) {
        DriveEntry updatedEntry = DriveEntry(
          id: widget.entryToEdit!.id, // Crucial for update
          customerName: customerName,
          dateTime: combinedDateTime,
          source: source,
          destination: destination,
          // type: widget.entryToEdit!.type, // Type is not changed in edit mode
        );
        try {
          await DatabaseHelper.instance.updateDriveEntry(updatedEntry);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Drive entry updated successfully!')),
          );
          // Schedule notification for the updated entry
          await notificationService.scheduleDriveNotification(updatedEntry);
          if (mounted) Navigator.pop(context, true); // Pop and signal success
        } catch (e) {
          print('Error updating drive entry: $e');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to update entry: $e')),
          );
        }
      } else { // Add new entry
        DriveEntry newEntry = DriveEntry(
          customerName: customerName,
          dateTime: combinedDateTime,
          source: source,
          destination: destination,
          type: _selectedType, // Use the selected type
        );

        try {
          final insertedId = await DatabaseHelper.instance.insertDriveEntry(newEntry);
          print('Inserted drive entry with id: $insertedId');

          // Create a DriveEntry instance that includes the ID for notification scheduling
          DriveEntry entryForNotification = DriveEntry(
            id: insertedId.toString(), // Use the ID returned from the database
            customerName: customerName,
            dateTime: combinedDateTime,
            source: source,
            destination: destination,
            type: _selectedType, // Include type for notification if needed
          );
          await notificationService.scheduleDriveNotification(entryForNotification);

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Drive entry saved successfully!')),
          );
          // Clear the form
          _customerNameController.clear();
          _dateController.clear();
          _timeController.clear();
          _sourceController.clear();
          _destinationController.clear();
          setState(() {
            _selectedDate = null;
            _selectedTime = null;
            _selectedType = 'trip'; // Reset type to default
          });
        } catch (e) {
          print('Error saving drive entry: $e');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to save entry: $e')),
          );
        }
      }
    }
  }

  @override
  void dispose() {
    // Clean up the controllers when the widget is disposed
    _customerNameController.dispose();
    _dateController.dispose();
    _timeController.dispose();
    _sourceController.dispose();
    _destinationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget formContent = Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey, // Wrap with SingleChildScrollView to prevent overflow
          child: SingleChildScrollView(
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // Type Selection
              const Text('Item Type:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              Row(
                children: <Widget>[
                  Expanded(
                    child: RadioListTile<String>(
                      title: const Text('Trip'),
                      value: 'trip',
                      groupValue: _selectedType,
                      // Disable type change in edit mode
                      onChanged: _isEditMode ? null : (String? value) {
                        if (value != null) setState(() => _selectedType = value);
                      },
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<String>(
                      title: const Text('Ticket'),
                      value: 'ticket',
                      groupValue: _selectedType,
                      // Disable type change in edit mode
                      onChanged: _isEditMode ? null : (String? value) {
                        if (value != null) setState(() => _selectedType = value);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16.0), // Space after type selection
              TextFormField(
                controller: _customerNameController,
                decoration: const InputDecoration(labelText: 'Customer Name'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter customer name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0), // Space between fields
              TextFormField(
                controller: _dateController,
                decoration: const InputDecoration(
                  labelText: 'Date',
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                readOnly: true,
                onTap: () => _selectDate(context),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a date';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                controller: _timeController,
                decoration: const InputDecoration(
                  labelText: 'Time',
                  suffixIcon: Icon(Icons.access_time),
                ),
                readOnly: true,
                onTap: () => _selectTime(context),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a time';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                controller: _sourceController,
                decoration: const InputDecoration(labelText: 'Source'),
                 validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter source location';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                controller: _destinationController,
                decoration: const InputDecoration(labelText: 'Destination'),
                 validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter destination location';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24.0),
              ElevatedButton(
                onPressed: _submitForm,
                child: Text(_isEditMode ? 'Update Entry' : 'Add Entry'),
              ),
            ],
          ),
          ),
        ),
      );

    if (_isEditMode) {
      // If in edit mode (navigated to directly), provide a Scaffold
      return Scaffold(
        appBar: AppBar(
          title: const Text('Edit Drive Entry'),
        ),
        body: formContent,
      );
    } else {
      // If in add mode (used as a tab), return just the form content
      return formContent;
    }
  }
}

// Placeholder screen for Settings
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late Future<List<DriveEntry>> _driveEntriesFuture;
  List<DriveEntry> _allEntries = [];
  final Set<String> _selectedEntryIds = {}; // Store String IDs from DriveEntry.id

  @override
  void initState() {
    super.initState();
    _refreshDriveEntries();
  }

  void _refreshDriveEntries() {
    setState(() {
      _driveEntriesFuture = DatabaseHelper.instance.getAllDriveEntries().then((entries) {
        _allEntries = entries;
        return entries;
      });
      _selectedEntryIds.clear(); // Clear selection on refresh
    });
  }

  void _toggleSelection(String entryId) {
    setState(() {
      if (_selectedEntryIds.contains(entryId)) {
        _selectedEntryIds.remove(entryId);
      } else {
        _selectedEntryIds.add(entryId);
      }
    });
  }

  Future<void> _deleteSelectedEntries() async {
    if (_selectedEntryIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No entries selected for deletion.')),
      );
      return;
    }

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Deletion'),
          content: Text('Are you sure you want to delete ${_selectedEntryIds.length} selected entries? This action cannot be undone.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      int successCount = 0;
      int failCount = 0;
      List<String> idsToDelete = List.from(_selectedEntryIds);

      for (String entryIdString in idsToDelete) {
          try {
            await DatabaseHelper.instance.deleteDriveEntry(entryIdString); // Pass the String ID
            await notificationService.cancelNotification(entryIdString); // Cancel notification
            successCount++;
          } catch (e) {
            print('Error deleting entry ID $entryIdString: $e');
            failCount++;
          } // This closes the catch block
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$successCount entries deleted. $failCount failed.')),
      );
      _refreshDriveEntries(); // Refresh the list and clear selection
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Drive Entries'),
        actions: [
          if (_selectedEntryIds.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined),
              tooltip: 'Delete Selected',
              onPressed: _deleteSelectedEntries,
            ),
        ],
      ),
      body: FutureBuilder<List<DriveEntry>>(
        future: _driveEntriesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error loading entries: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                'No drive entries found.',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            );
          } else {
            // _allEntries is updated by _refreshDriveEntries
            return ListView.builder(
              itemCount: _allEntries.length,
              itemBuilder: (context, index) {
                final entry = _allEntries[index];
                // DriveEntry.id is String?, but should be non-null for DB entries
                final isSelected = entry.id != null && _selectedEntryIds.contains(entry.id!);
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
                  child: CheckboxListTile(
                    title: Text(entry.customerName),
                    subtitle: Text(
                        '${entry.source} to ${entry.destination}\n${entry.dateTime.toLocal().toString().substring(0, 16)}'),
                    value: isSelected,
                    onChanged: entry.id == null ? null : (bool? selected) {
                      _toggleSelection(entry.id!);
                    },
                    secondary: Icon(isSelected ? Icons.check_box : Icons.check_box_outline_blank),
                    isThreeLine: true,
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}
