// lib/models/car_video_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class CarVideo {
  final String id;
  final String customerId;
  final String carId;
  final DateTime timestamp;
  final String videoUrl;
  final String? fuelImageUrl;  // ← now properly typed as String?

  CarVideo({
    required this.id,
    required this.customerId,
    required this.carId,
    required this.timestamp,
    required this.videoUrl,
    this.fuelImageUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'customerId': customerId,
      'carId':       carId,
      'timestamp':   Timestamp.fromDate(timestamp),
      'videoUrl':    videoUrl,
      if (fuelImageUrl != null) 'fuelImageUrl': fuelImageUrl,
    };
  }

  factory CarVideo.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return CarVideo(
      id:            doc.id,
      customerId:    data['customerId']   as String,
      carId:         data['carId']        as String,
      timestamp:     (data['timestamp']   as Timestamp).toDate(),
      videoUrl:      data['videoUrl']     as String,
      fuelImageUrl:  data['fuelImageUrl'] as String?,  // ← safely cast
    );
  }
}
