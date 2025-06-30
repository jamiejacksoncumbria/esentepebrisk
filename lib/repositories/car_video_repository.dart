// lib/repositories/car_video_repository.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import '../models/car_video_model.dart';

class CarVideoRepository {
  final _col = FirebaseFirestore.instance.collection('carVideos');

  /// Streams videos for a specific customer.
  /// Logs any snapshot errors in debug mode.
  Stream<List<CarVideo>> streamForCustomer(String custId) {
    return _col
        .where('customerId', isEqualTo: custId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .handleError((error, stack) {
      if (kDebugMode) {
        debugPrint(
          '[CarVideoRepository.streamForCustomer] '
              'custId=$custId error: $error\n$stack',
        );
      }
    })
        .map((snap) => snap.docs
        .map((d) => CarVideo.fromDoc(
        d as DocumentSnapshot<Map<String, dynamic>>))
        .toList());
  }

  /// Adds a new video record.
  /// Logs errors in debug mode before rethrowing.
  Future<void> addVideo(CarVideo cv) async {
    try {
      await _col.add(cv.toMap());
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint(
          '[CarVideoRepository.addVideo] '
              'customerId=${cv.customerId} error: $e\n$st',
        );
      }
      rethrow;
    }
  }

  /// Deletes a video by its Firestore document ID.
  /// Logs errors in debug mode before rethrowing.
  Future<void> deleteVideo(String id) async {
    try {
      await _col.doc(id).delete();
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint(
          '[CarVideoRepository.deleteVideo] id=$id error: $e\n$st',
        );
      }
      rethrow;
    }
  }
  /// ★ NEW ★
  /// Stream *all* videos whose `timestamp` falls between [start] and [end].
  Stream<List<CarVideo>> streamBetweenDates(
      DateTime start, DateTime end) {
    return _col
        .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(end))
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snap) => snap.docs
        .map((d) => CarVideo.fromDoc(
        d as DocumentSnapshot<Map<String, dynamic>>))
        .toList());
  }

}
