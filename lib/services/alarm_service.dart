import 'package:alarm/alarm.dart';
import '../features/drive/domain/entities/drive_entity.dart';

class AlarmService {
  static final AlarmService _instance = AlarmService._internal();

  factory AlarmService() {
    return _instance;
  }

  AlarmService._internal();

  Future<void> init() async {
    await Alarm.init();
  }

  Future<void> scheduleDriveAlarm(DriveEntity entry) async {
    if (entry.id == null) {
      print('Error: DriveEntry ID is null. Cannot schedule alarm.');
      return;
    }

    final int alarmId = entry.id ?? entry.hashCode;

    if (entry.alarmOffsetMinutes == null) {
      print('Alarm offset is null. Cancelling alarm if exists for entry ${entry.id}.');
      await Alarm.stop(alarmId);
      return;
    }

    final DateTime scheduledTime = entry.dateTime.subtract(Duration(minutes: entry.alarmOffsetMinutes!));

    if (scheduledTime.isBefore(DateTime.now())) {
      print('Alarm time for entry ${entry.id} is in the past. Not scheduling.');
      return;
    }

    final alarmSettings = AlarmSettings(
      id: alarmId,
      dateTime: scheduledTime,
      assetAudioPath: 'assets/alarm_sound.mp3',
      loopAudio: true,
      vibrate: true,
      volumeSettings: VolumeSettings.fade(
        volume: 1.0,
        volumeEnforced: true,
        fadeDuration: const Duration(seconds: 3),
      ),
      notificationSettings: NotificationSettings(
        title: '🚗 Time to Drive! (${entry.customerName})',
        body: 'Upcoming trip from ${entry.source} to ${entry.destination}. Drive safely!',
        stopButton: 'Dismiss',
      ),
    );

    await Alarm.set(alarmSettings: alarmSettings);
    print('Scheduled alarm ID $alarmId for entry ${entry.id} at $scheduledTime');
  }

  Future<void> cancelAlarm(String entryIdString) async {
    final int? alarmId = int.tryParse(entryIdString);
    if (alarmId != null) {
      await Alarm.stop(alarmId);
      print('Cancelled alarm for entry ID $alarmId');
    } else {
      print('Error: Could not parse entryIdString to int for cancellation: $entryIdString');
    }
  }
}

final AlarmService alarmService = AlarmService();
