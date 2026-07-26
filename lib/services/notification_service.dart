import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import '../features/drive/domain/entities/drive_entity.dart';

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

    // timezones are initialized in main.dart
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

  Future<void> scheduleDriveNotification(DriveEntity entry) async {
    if (entry.id == null) {
      print('Error: DriveEntry ID is null. Cannot schedule notification.');
      return;
    }
    final int notificationId = entry.id ?? entry.hashCode;
    final tz.TZDateTime scheduledTime =
        tz.TZDateTime.from(entry.dateTime.subtract(const Duration(days: 1)), tz.local);

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
      'Drive for ${entry.customerName} on ${entry.dateTime.toLocal().toString().substring(0, 10)} at ${entry.dateTime.toLocal().toString().substring(11, 16)}. Pickup: ${entry.source} to Drop: ${entry.destination}. (Tomorrow)',
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
