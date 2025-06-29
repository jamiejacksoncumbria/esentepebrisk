import 'package:cloud_firestore/cloud_firestore.dart';

class ChildSeat {
  final String id;
  final String type;
  final String age; // free‐form string, e.g. "1–2 years"

  const ChildSeat({
    required this.id,
    required this.type,
    required this.age,
  });

  Map<String, dynamic> toMap() => {
    'type': type,
    'age': age,
  };

  factory ChildSeat.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return ChildSeat(
      id: doc.id,
      type: data['type'] as String,
      age: data['age'] as String,
    );
  }

  ChildSeat copyWith({
    String? type,
    String? age,
  }) =>
      ChildSeat(
        id: id,
        type: type ?? this.type,
        age: age ?? this.age,
      );
}
