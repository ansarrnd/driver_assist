enum DriveType {
  trip,
  ticket;

  String get value => name;

  static DriveType fromString(String value) {
    return DriveType.values.firstWhere(
      (type) => type.name == value,
      orElse: () => DriveType.trip,
    );
  }
}
