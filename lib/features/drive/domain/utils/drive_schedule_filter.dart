import '../entities/drive_entity.dart';
import '../entities/drive_type.dart';

enum DriveSchedulePeriod {
  today,
  week,
  month,
}

extension DriveSchedulePeriodLabel on DriveSchedulePeriod {
  String get label {
    switch (this) {
      case DriveSchedulePeriod.today:
        return 'Today';
      case DriveSchedulePeriod.week:
        return 'Week';
      case DriveSchedulePeriod.month:
        return 'Month';
    }
  }

  static DriveSchedulePeriod fromLabel(String label) {
    return DriveSchedulePeriod.values.firstWhere(
      (period) => period.label == label,
      orElse: () => DriveSchedulePeriod.month,
    );
  }
}

List<DriveEntity> filterDriveEntries({
  required List<DriveEntity> entries,
  required DriveType type,
  required DriveSchedulePeriod period,
  DateTime? referenceTime,
}) {
  final typeFilteredEntries = entries.where((entry) => entry.type == type).toList();
  final now = referenceTime ?? DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  switch (period) {
    case DriveSchedulePeriod.today:
      return typeFilteredEntries.where((entry) {
        final entryDate = DateTime(entry.dateTime.year, entry.dateTime.month, entry.dateTime.day);
        return entryDate.isAtSameMomentAs(today);
      }).toList();
    case DriveSchedulePeriod.week:
      final startOfWeek = today.subtract(Duration(days: today.weekday - 1));
      final endOfWeek = startOfWeek.add(const Duration(days: 6));
      return typeFilteredEntries.where((entry) {
        final entryDate = DateTime(entry.dateTime.year, entry.dateTime.month, entry.dateTime.day);
        return !entryDate.isBefore(startOfWeek) && !entryDate.isAfter(endOfWeek);
      }).toList();
    case DriveSchedulePeriod.month:
      return typeFilteredEntries.where((entry) {
        return entry.dateTime.year == now.year && entry.dateTime.month == now.month;
      }).toList();
  }
}
