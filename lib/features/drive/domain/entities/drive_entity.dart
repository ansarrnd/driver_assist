import 'package:equatable/equatable.dart';

class DriveEntity extends Equatable {
  final int? id;
  final String customerName;
  final String source;
  final String destination;
  final DateTime dateTime;
  final String type;
  final int? alarmOffsetMinutes;

  const DriveEntity({
    this.id,
    required this.customerName,
    required this.source,
    required this.destination,
    required this.dateTime,
    this.type = 'trip',
    this.alarmOffsetMinutes,
  });

  factory DriveEntity.fromJson(Map<String, dynamic> json) {
    return DriveEntity(
      id: json['_id'] as int?,
      customerName: json['customerName'] as String,
      source: json['source'] as String,
      destination: json['destination'] as String,
      dateTime: DateTime.parse(json['dateTime'] as String),
      type: json['type'] as String? ?? 'trip',
      alarmOffsetMinutes: json['alarmOffsetMinutes'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'customerName': customerName,
      'source': source,
      'destination': destination,
      'dateTime': dateTime.toIso8601String(),
      'type': type,
      'alarmOffsetMinutes': alarmOffsetMinutes,
    };
  }

  DriveEntity copyWith({
    int? id,
    String? customerName,
    String? source,
    String? destination,
    DateTime? dateTime,
    String? type,
    int? alarmOffsetMinutes,
  }) {
    return DriveEntity(
      id: id ?? this.id,
      customerName: customerName ?? this.customerName,
      source: source ?? this.source,
      destination: destination ?? this.destination,
      dateTime: dateTime ?? this.dateTime,
      type: type ?? this.type,
      alarmOffsetMinutes: alarmOffsetMinutes ?? this.alarmOffsetMinutes,
    );
  }

  @override
  List<Object?> get props => [id, customerName, source, destination, dateTime, type, alarmOffsetMinutes];
}
