import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/transfer_model.dart';
import '../models/transfer_query.dart';

class TransferRepository {
  final CollectionReference<Map<String,dynamic>> _col =
  FirebaseFirestore.instance.collection('transfers');

  Stream<List<TransferModel>> streamByQuery(TransferQuery q) {
    var ref = _col
        .where('type', isEqualTo: q.type.name)
        .where('collectionDateAndTime',
        isGreaterThanOrEqualTo: Timestamp.fromDate(q.start))
        .where('collectionDateAndTime',
        isLessThanOrEqualTo: Timestamp.fromDate(q.end))
        .orderBy('collectionDateAndTime');
    return ref.snapshots().map((snap) =>
        snap.docs.map((d) => TransferModel.fromMap(d.data())).toList());
  }

  Future<DocumentReference> addTransfer(TransferModel t) {
    return _col.add(t.toMap());
  }

  Future<void> updateTransfer(TransferModel t) {
    return _col.doc(t.collectionUUID).update(t.toMap());
  }
}
