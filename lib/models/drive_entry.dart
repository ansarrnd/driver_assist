import '../database_helper.dart';

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
