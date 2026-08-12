import 'package:alarm/alarm.dart';
import 'package:flutter/foundation.dart';

import '../features/drive/domain/entities/drive_entity.dart';

abstract class AlarmScheduler {
  Future<void> scheduleDriveAlarm(DriveEntity entry);
  Future<void> cancelAlarm(String entryId);
  Future<void> rescheduleAll(List<DriveEntity> drives);
}

class AlarmService implements AlarmScheduler {
  static final AlarmService _instance = AlarmService._internal();

  factory AlarmService() => _instance;

  AlarmService._internal();

  Future<void> init() async {
    await Alarm.init();
  }

  int alarmIdForEntry(String entryId) => entryId.hashCode & 0x7FFFFFFF;

  @override
  Future<void> scheduleDriveAlarm(DriveEntity entry) async {
    if (entry.id == null) {
      debugPrint('Cannot schedule alarm: drive entry id is null.');
      return;
    }

    final alarmId = alarmIdForEntry(entry.id!);

    if (entry.alarmOffsetMinutes == null) {
      await Alarm.stop(alarmId);
      return;
    }

    final scheduledTime = entry.dateTime.subtract(
      Duration(minutes: entry.alarmOffsetMinutes!),
    );

    if (scheduledTime.isBefore(DateTime.now())) {
      await Alarm.stop(alarmId);
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
  }

  @override
  Future<void> cancelAlarm(String entryId) async {
    await Alarm.stop(alarmIdForEntry(entryId));
  }

  @override
  Future<void> rescheduleAll(List<DriveEntity> drives) async {
    for (final drive in drives) {
      await scheduleDriveAlarm(drive);
    }
  }
}

final AlarmService alarmService = AlarmService();
