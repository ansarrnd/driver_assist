import 'package:sqflite/sqflite.dart';
import '../../../../core/database/database_helper.dart';
import '../../domain/entities/drive_entity.dart';

abstract class DriveLocalDataSource {
  Future<List<DriveEntity>> getDrives();
  Future<int> addDrive(DriveEntity drive);
  Future<int> deleteDrive(int id);
}

class DriveLocalDataSourceImpl implements DriveLocalDataSource {
  final DatabaseHelper databaseHelper;

  DriveLocalDataSourceImpl(this.databaseHelper);

  @override
  Future<List<DriveEntity>> getDrives() async {
    final db = await databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(DatabaseHelper.tableDriveEntries, orderBy: 'dateTime DESC');
    return List.generate(maps.length, (i) {
      return DriveEntity.fromJson(maps[i]);
    });
  }

  @override
  Future<int> addDrive(DriveEntity drive) async {
    final db = await databaseHelper.database;
    return await db.insert(
      DatabaseHelper.tableDriveEntries,
      drive.toJson()..remove('_id'),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<int> deleteDrive(int id) async {
    final db = await databaseHelper.database;
    return await db.delete(
      DatabaseHelper.tableDriveEntries,
      where: '_id = ?',
      whereArgs: [id],
    );
  }
}
