import 'package:cloud_firestore/cloud_firestore.dart';

class Airport {
  final String id;
  final String name;
  final String code;
  final double cost;
  final int pickupOffsetMinutes; // ← now in minutes

  Airport({
    required this.id,
    required this.name,
    required this.code,
    required this.cost,
    required this.pickupOffsetMinutes,
  });

  Map<String, dynamic> toMap() => {
    'name': name,
    'code': code,
    'cost': cost,
    'pickupOffsetMinutes': pickupOffsetMinutes,
  };

  factory Airport.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Airport(
      id: doc.id,
      name: data['name'] as String? ?? '',
      code: data['code'] as String? ?? '',
      cost: (data['cost'] as num?)?.toDouble() ?? 0.0,
      pickupOffsetMinutes: (data['pickupOffsetMinutes'] as num?)?.toInt() ?? 0,
    );
  }
}
