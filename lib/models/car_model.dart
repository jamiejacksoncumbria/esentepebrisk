// lib/models/car_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Car {
  final String id;
  final String make;
  final String model;
  final String registration;

  Car({
    required this.id,
    required this.make,
    required this.model,
    required this.registration,
  });

  Map<String, dynamic> toMap() => {
    'make': make,
    'model': model,
    'registration': registration,
  };

  factory Car.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Car(
      id: doc.id,
      make: data['make'] as String? ?? '',
      model: data['model'] as String? ?? '',
      registration: data['registration'] as String? ?? '',
    );
  }
}
