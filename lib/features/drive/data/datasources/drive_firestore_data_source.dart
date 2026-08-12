import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/drive_entity.dart';
import '../mock/mock_drive_entries.dart';

abstract class DriveFirestoreDataSource {
  Future<List<DriveEntity>> getDrives();
  Future<String> addDrive(DriveEntity drive);
  Future<void> updateDrive(DriveEntity drive);
  Future<void> deleteDrive(String id);
  Future<void> seedMockDataIfEmpty();
}

class DriveFirestoreDataSourceImpl implements DriveFirestoreDataSource {
  final FirebaseFirestore firestore;

  DriveFirestoreDataSourceImpl(this.firestore);

  CollectionReference<Map<String, dynamic>> get _collection =>
      firestore.collection(MockDriveEntries.collectionName);

  @override
  Future<List<DriveEntity>> getDrives() async {
    final snapshot = await _collection
        .orderBy('dateTime', descending: true)
        .get();
    return snapshot.docs
        .map((doc) => DriveEntity.fromFirestore(doc.id, doc.data()))
        .toList();
  }

  @override
  Future<String> addDrive(DriveEntity drive) async {
    final docRef = await _collection.add(drive.toFirestore());
    return docRef.id;
  }

  @override
  Future<void> updateDrive(DriveEntity drive) async {
    if (drive.id == null) {
      throw StateError('Cannot update a drive entry without an id.');
    }

    await _collection.doc(drive.id).set(drive.toFirestore());
  }

  @override
  Future<void> deleteDrive(String id) async {
    await _collection.doc(id).delete();
  }

  @override
  Future<void> seedMockDataIfEmpty() async {
    final snapshot = await _collection.limit(1).get();
    if (snapshot.docs.isNotEmpty) {
      return;
    }

    final batch = firestore.batch();
    for (final entry in MockDriveEntries.entries()) {
      final docRef = _collection.doc();
      batch.set(docRef, entry.toFirestore());
    }
    await batch.commit();
  }
}
