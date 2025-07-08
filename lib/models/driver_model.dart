import 'package:cloud_firestore/cloud_firestore.dart';

class Driver {
  final String id;                          // Firestore doc id
  final String uuid;                        // driver’s UUID
  final String name;
  final String email;
  final String phone;
  final String whatsapp;
  final Map<String,double> commissionRates; // airportId → rate
  final int colorValue;                     // ← new: ARGB color value

  Driver({
    required this.id,
    required this.uuid,
    required this.name,
    required this.email,
    required this.phone,
    required this.whatsapp,
    required this.commissionRates,
    required this.colorValue,                // ← new
  });

  Map<String, dynamic> toMap() => {
    'uuid': uuid,
    'name': name,
    'email': email,
    'phone': phone,
    'whatsapp': whatsapp,
    'commissionRates': commissionRates,
    'colorValue': colorValue,               // ← new
  };

  factory Driver.fromDoc(DocumentSnapshot<Map<String,dynamic>> doc) {
    final data = doc.data()!;
    final raw = data['commissionRates'] as Map<String, dynamic>? ?? {};
    final rates = raw.map((k, v) => MapEntry(k, (v as num).toDouble()));
    return Driver(
      id: doc.id,
      uuid: data['uuid'] as String? ?? '',
      name: data['name'] as String? ?? '',
      email: data['email'] as String? ?? '',
      phone: data['phone'] as String? ?? '',
      whatsapp: data['whatsapp'] as String? ?? '',
      commissionRates: rates,
      colorValue: data['colorValue'] as int? ?? 0xFF2196F3, // default blue
    );
  }

  Driver copyWith({
    String? uuid,
    String? name,
    String? email,
    String? phone,
    String? whatsapp,
    Map<String,double>? commissionRates,
    int? colorValue,                         // ← new
  }) =>
      Driver(
        id: id,
        uuid: uuid ?? this.uuid,
        name: name ?? this.name,
        email: email ?? this.email,
        phone: phone ?? this.phone,
        whatsapp: whatsapp ?? this.whatsapp,
        commissionRates: commissionRates ?? this.commissionRates,
        colorValue: colorValue ?? this.colorValue,  // ← new
      );
}
