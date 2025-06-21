// lib/models/airport_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Airport {
  final String id;
  final String name;
  final String code;

  Airport({
    required this.id,
    required this.name,
    required this.code,
  });

  Map<String, dynamic> toMap() => {
    'name': name,
    'code': code,
  };

  factory Airport.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Airport(
      id: doc.id,
      name: data['name'] as String? ?? '',
      code: data['code'] as String? ?? '',
    );
  }
}
