import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/staff_model.dart';

class StaffRepository {
  final CollectionReference _col = FirebaseFirestore.instance.collection('staff');

  Stream<List<Staff>> streamStaff() {
    return _col.snapshots().map((snap) =>
        snap.docs.map((doc) => Staff.fromFirestore(doc.data() as Map<String, dynamic>, doc.id)).toList()
    );
  }

  Future<void> addStaff(Staff s) => _col.add(s.toJson());

  Future<void> updateStaff(Staff s) => _col.doc(s.id).update(s.toJson());

  Future<void> deleteStaff(String id) => _col.doc(id).delete();
}
