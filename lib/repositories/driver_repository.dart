import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/driver_model.dart';

class DriverRepository {
  final _col = FirebaseFirestore.instance.collection('drivers');

  Stream<List<Driver>> streamDrivers() {
    return _col
        .orderBy('name')
        .snapshots()
        .map((snap) => snap.docs
        .map((d) => Driver.fromDoc(d as DocumentSnapshot<Map<String,dynamic>>))
        .toList());
  }

  Future<void> addDriver(Driver d) => _col.add(d.toMap());

  Future<void> updateDriver(Driver d) => _col.doc(d.id).update(d.toMap());

  Future<void> deleteDriver(String id) => _col.doc(id).delete();
}
