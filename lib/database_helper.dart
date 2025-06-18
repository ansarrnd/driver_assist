// For TimeOfDay
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'main.dart'; // Assuming DriveEntry is in main.dart

class DatabaseHelper {
  static const _databaseName = "DriveScheduleApp.db";
  static const _databaseVersion = 3; // Incremented version for 'type' column

  static const tableDriveEntries = 'drive_entries';

  static const columnId = '_id'; // SQLite convention for primary key
  static const columnCustomerName = 'customerName';
  static const columnDateTime = 'dateTime'; // Store as TEXT (ISO8601)
  static const columnSource = 'source';
  static const columnDestination = 'destination';
  static const columnType = 'type'; // New column for 'trip' or 'ticket'

  // Make this a singleton class
  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  // Only have a single app-wide reference to the database
  static Database? _database;
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  // This opens the database (and creates it if it doesn't exist)
  Future<Database> _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, _databaseName);
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade, // Add onUpgrade
    );
  }

  // SQL code to create the database table
  Future _onCreate(Database db, int version) async {
    await db.execute('''
          CREATE TABLE $tableDriveEntries (
            $columnId INTEGER PRIMARY KEY AUTOINCREMENT,
            $columnCustomerName TEXT NOT NULL,
            $columnDateTime TEXT NOT NULL,
            $columnSource TEXT NOT NULL,
            $columnDestination TEXT NOT NULL,
            $columnType TEXT NOT NULL DEFAULT 'trip' -- Add type column with default
          )
          ''');
  }

  // SQL code to upgrade the database table
  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 3) {
      // Add the 'type' column if upgrading from a version before 3
      await db.execute('ALTER TABLE $tableDriveEntries ADD COLUMN $columnType TEXT NOT NULL DEFAULT \'trip\'');
    }
    // Add other upgrade paths here if needed for future versions
  }

  // Inserts a row in the database. The return value is the id of the inserted row.
  // The type is included in entry.toMap()
  Future<int> insertDriveEntry(DriveEntry entry) async {
    Database db = await instance.database;
    return await db.insert(tableDriveEntries, entry.toMap());
  }

  // Retrieves all rows from the drive_entries table.
  Future<List<DriveEntry>> getAllDriveEntries() async {
    Database db = await instance.database;
    // Query the table for all The Entries.
    final List<Map<String, dynamic>> maps = await db.query(
      tableDriveEntries,
      orderBy: "$columnId DESC",
    );

    // Convert the List<Map<String, dynamic>> into a List<DriveEntry>.
    if (maps.isEmpty) {
      return [];
    }
    return List.generate(maps.length, (i) {
      return DriveEntry.fromMap(maps[i]);
    });
  }

  // Retrieves entries of a specific type
  Future<List<DriveEntry>> getDriveEntriesByType(String type) async {
    Database db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableDriveEntries,
      where: '$columnType = ?',
      whereArgs: [type],
      orderBy: "$columnId DESC",
    );

    // Convert the List<Map<String, dynamic>> into a List<DriveEntry>.
    if (maps.isEmpty) {
      return [];
    }
    return List.generate(maps.length, (i) {
      return DriveEntry.fromMap(maps[i]);
    });
  }

  // We are assuming here that the id column in the map is the primary key
  Future<int> updateDriveEntry(DriveEntry entry) async {
    Database db = await instance.database;
    return await db.update(
      tableDriveEntries,
      entry.toMap(),
      where: '$columnId = ?',
      whereArgs: [entry.id],
    );
  }

  Future<int> deleteDriveEntry(String id) async {
    Database db = await instance.database;
    return await db.delete(
      tableDriveEntries,
      where: '$columnId = ?',
      whereArgs: [int.parse(id)], // Assuming id in DriveEntry is String, but DB stores int
    );
  }
}
