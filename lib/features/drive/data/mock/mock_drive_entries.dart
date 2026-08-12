import '../../domain/entities/drive_entity.dart';
import '../../domain/entities/drive_type.dart';

/// Mock Firestore documents used to seed an empty `drive_entries` collection.
class MockDriveEntries {
  static const String collectionName = 'drive_entries';

  static List<DriveEntity> entries() {
    final now = DateTime.now();

    return [
      DriveEntity(
        customerName: 'Rajesh Kumar',
        source: 'Kempegowda International Airport T1',
        destination: 'MG Road, Bengaluru',
        dateTime: DateTime(now.year, now.month, now.day, 6, 30).add(const Duration(days: 1)),
        type: DriveType.trip,
        alarmOffsetMinutes: 60,
      ),
      DriveEntity(
        customerName: 'Priya Sharma',
        source: 'Indiranagar Metro Station',
        destination: 'Electronic City Phase 1',
        dateTime: DateTime(now.year, now.month, now.day, 8, 0).add(const Duration(days: 2)),
        type: DriveType.trip,
        alarmOffsetMinutes: 30,
      ),
      DriveEntity(
        customerName: 'Michael Chen',
        source: 'Chennai Central Railway Station',
        destination: 'OMR Sholinganallur',
        dateTime: DateTime(now.year, now.month, now.day, 17, 45).add(const Duration(days: 3)),
        type: DriveType.ticket,
        alarmOffsetMinutes: 1440,
      ),
      DriveEntity(
        customerName: 'Anita Desai',
        source: 'Pune Railway Station',
        destination: 'Hinjewadi IT Park',
        dateTime: DateTime(now.year, now.month, now.day, 9, 15).add(const Duration(days: 4)),
        type: DriveType.ticket,
        alarmOffsetMinutes: 60,
      ),
      DriveEntity(
        customerName: 'David Wilson',
        source: 'Hyderabad Airport',
        destination: 'Gachibowli Financial District',
        dateTime: DateTime(now.year, now.month, now.day, 22, 0).add(const Duration(days: 5)),
        type: DriveType.trip,
        alarmOffsetMinutes: 15,
      ),
      DriveEntity(
        customerName: 'Sneha Reddy',
        source: 'Secunderabad Railway Station',
        destination: 'Banjara Hills',
        dateTime: DateTime(now.year, now.month, now.day, 7, 0).add(const Duration(days: 6)),
        type: DriveType.ticket,
      ),
    ];
  }
}
