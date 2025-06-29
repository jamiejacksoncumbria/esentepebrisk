// lib/models/airport_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class Airport {
  final String id;
  final String name;
  final String code;
  final double cost;  // ← new

  Airport({
    required this.id,
    required this.name,
    required this.code,
    required this.cost,  // ← new
  });

  Map<String, dynamic> toMap() => {
    'name': name,
    'code': code,
    'cost': cost,     // ← include in map
  };

  factory Airport.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Airport(
      id: doc.id,
      name: data['name'] as String? ?? '',
      code: data['code'] as String? ?? '',
      cost: (data['cost'] as num?)?.toDouble() ?? 0.0,  // ← parse double safely
    );
  }
}
