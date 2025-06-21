// lib/repositories/staff_repository.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/staff_model.dart';

class StaffRepository {
  final FirebaseFirestore _firestore;

  StaffRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference get _col => _firestore.collection('staff');

  /// Streams staff ordered by first name (field `name`), then last name.
  ///
  /// Make sure you’ve created a composite index on ['name','lastName'] in the
  /// Firestore console—or click the link Firestore gives you on first run.
  Stream<List<Staff>> streamStaff() {
    return _col
        .orderBy('name')
        .orderBy('lastName')
        .snapshots()
        .map((snap) => snap.docs
        .map((doc) => Staff.fromFirestore(
      doc.data() as Map<String, dynamic>,
      doc.id,
    ))
        .toList());
  }

  Future<void> addStaff(Staff s) => _col.add(s.toJson());

  Future<void> updateStaff(Staff s) =>
      _col.doc(s.id).update(s.toJson());

  Future<void> deleteStaff(String id) => _col.doc(id).delete();
}
