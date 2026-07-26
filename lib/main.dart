import 'package:flutter/material.dart';
import 'dart:io';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'database_helper.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';

import 'theme.dart';
import 'models/drive_entry.dart';
import 'services/notification_service.dart';
import 'screens/home_page.dart';
import 'package:provider/provider.dart';
import 'theme_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Ensure bindings are initialized

  // Initialize FFI for sqflite on desktop platforms
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  tz.initializeTimeZones(); // Fix: Initialize timezones here
  await notificationService.init();
  await notificationService.requestPermissions();

  // Fetch all existing drive entries and schedule notifications for them
  if (Platform.isAndroid) {
    await AndroidAlarmManager.initialize(); // Initialize AlarmManager
  }

  try {
    final List<DriveEntry> allEntries = await DatabaseHelper.instance.getAllDriveEntries();
    for (final DriveEntry entry in allEntries) {
      // 1. Schedule 1-day pre-notification using flutter_local_notifications
      await notificationService.scheduleDriveNotification(entry);

      // 2. Schedule AndroidAlarmManager for the actual drive time for lapsed handling
      if (entry.id != null) {
        final int? entryIntId = int.tryParse(entry.id!);
        if (entryIntId != null) {
          final int alarmId = entryIntId + _alarmManagerIdOffset;
          // Only schedule for future drives
          if (entry.dateTime.isAfter(DateTime.now())) {
            if (Platform.isAndroid) {
              print('Scheduling AndroidAlarmManager for entry ${entry.id} at ${entry.dateTime} with alarm ID $alarmId');
              await AndroidAlarmManager.oneShotAt(
                entry.dateTime,
                alarmId,
                myCallback,
                exact: true,
                wakeup: true,
                rescheduleOnReboot: true,
              );
            }
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

  final int originalEntryId = alarmId - _alarmManagerIdOffset;

  // Initialize DB for background isolate
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  DriveEntry? entry;
  try {
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
  }

  if (entry == null) {
    print('Lapsed Alarm: Entry with original ID $originalEntryId not found in myCallback.');
    return;
  }

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher'); // Default icon

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

  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

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
    'Drive for ${entry.customerName} from Pickup: ${entry.source} to Drop: ${entry.destination} was scheduled for ${entry.dateTime.toLocal().toString().substring(11, 16)}.',
    lapsedNotificationDetails,
    payload: 'lapsed_drive_${entry.id}',
  );

  final List<ActiveNotification> activeGroupNotifications = [];
  final allActive = await flutterLocalNotificationsPlugin.getActiveNotifications();
  for (final activeNotification in allActive) {
    if (activeNotification.groupKey == LAPSED_DRIVES_GROUP_KEY && activeNotification.id != LAPSED_DRIVES_SUMMARY_NOTIFICATION_ID) {
        activeGroupNotifications.add(activeNotification);
    }
  }

  int totalLapsedInSummary = activeGroupNotifications.length;
  if (!activeGroupNotifications.any((n) => n.id == originalEntryId)) {
      totalLapsedInSummary++;
  }

  List<String> summaryLines = activeGroupNotifications
      .map((n) => n.title ?? "Lapsed Drive") // Use title from active notification
      .take(5) // Limit lines in summary
      .toList();

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
    return ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'Driver Schedule',
            theme: themeProvider.themeData,
            home: const MyHomePage(title: 'Flutter Demo Home Page'),
          );
        },
      ),
    );
  }
}

