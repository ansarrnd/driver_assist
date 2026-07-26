// For TimeOfDay
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';


class DatabaseHelper {
  static const _databaseName = "DriveScheduleApp.db";
  static const _databaseVersion = 4; // Incremented version

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

}
