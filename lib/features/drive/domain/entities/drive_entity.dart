import 'package:equatable/equatable.dart';
import 'drive_type.dart';

class DriveEntity extends Equatable {
  final String? id;
  final String customerName;
  final String source;
  final String destination;
  final DateTime dateTime;
  final DriveType type;
  final int? alarmOffsetMinutes;

  const DriveEntity({
    this.id,
    required this.customerName,
    required this.source,
    required this.destination,
    required this.dateTime,
    this.type = DriveType.trip,
    this.alarmOffsetMinutes,
  });

  factory DriveEntity.fromFirestore(String id, Map<String, dynamic> data) {
    return DriveEntity(
      id: id,
      customerName: data['customerName'] as String,
      source: data['source'] as String,
      destination: data['destination'] as String,
      dateTime: DateTime.parse(data['dateTime'] as String),
      type: DriveType.fromString(data['type'] as String? ?? 'trip'),
      alarmOffsetMinutes: data['alarmOffsetMinutes'] as int?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'customerName': customerName,
      'source': source,
      'destination': destination,
      'dateTime': dateTime.toIso8601String(),
      'type': type.value,
      'alarmOffsetMinutes': alarmOffsetMinutes,
    };
  }

  DriveEntity copyWith({
    String? id,
    String? customerName,
    String? source,
    String? destination,
    DateTime? dateTime,
    DriveType? type,
    int? alarmOffsetMinutes,
    bool clearAlarmOffset = false,
  }) {
    return DriveEntity(
      id: id ?? this.id,
      customerName: customerName ?? this.customerName,
      source: source ?? this.source,
      destination: destination ?? this.destination,
      dateTime: dateTime ?? this.dateTime,
      type: type ?? this.type,
      alarmOffsetMinutes: clearAlarmOffset
          ? null
          : (alarmOffsetMinutes ?? this.alarmOffsetMinutes),
    );
  }

  @override
  List<Object?> get props => [
    id,
    customerName,
    source,
    destination,
    dateTime,
    type,
    alarmOffsetMinutes,
  ];
}
