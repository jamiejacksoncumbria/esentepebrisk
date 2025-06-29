import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/child_seat_model.dart';

class ChildSeatRepository {
  final CollectionReference<Map<String, dynamic>> _col =
  FirebaseFirestore.instance.collection('childSeats');

  Stream<List<ChildSeat>> streamChildSeats() {
    return _col
        .orderBy('type')
        .snapshots()
        .map((snap) => snap.docs
        .map((doc) => ChildSeat.fromDoc(doc))
        .toList());
  }

  Future<void> addChildSeat(String type, String age) {
    return _col.add({'type': type, 'age': age});
  }

  Future<void> updateChildSeat(String id, String type, String age) {
    return _col.doc(id).update({'type': type, 'age': age});
  }

  Future<void> deleteChildSeat(String id) {
    return _col.doc(id).delete();
  }
}
