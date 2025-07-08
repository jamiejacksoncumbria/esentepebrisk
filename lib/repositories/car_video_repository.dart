import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/car_video_model.dart';

class CarVideoRepository {
  final _col = FirebaseFirestore.instance.collection('carVideos');

  Stream<List<CarVideo>> streamForCustomer(String custId) {
    return _col
        .where('customerId', isEqualTo: custId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snap) => snap.docs
        .map((d) => CarVideo.fromDoc(d as DocumentSnapshot<Map<String, dynamic>>))
        .toList());
  }

  /// NEW: all videos between two instants (inclusive)
  Stream<List<CarVideo>> streamBetweenDates(DateTime start, DateTime end) {
    final startTs = Timestamp.fromDate(start);
    final endTs = Timestamp.fromDate(end);
    return _col
        .where('timestamp', isGreaterThanOrEqualTo: startTs)
        .where('timestamp', isLessThanOrEqualTo: endTs)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snap) => snap.docs
        .map((d) => CarVideo.fromDoc(d as DocumentSnapshot<Map<String, dynamic>>))
        .toList());
  }

  Future<void> addVideo(CarVideo cv) => _col.add(cv.toMap());
  Future<void> deleteVideo(String id) => _col.doc(id).delete();
}
