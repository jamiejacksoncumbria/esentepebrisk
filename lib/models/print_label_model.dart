import 'package:cloud_firestore/cloud_firestore.dart';

class PrintLabel {
  final String id;
  final String customerId;
  final String customerName;
  final String phone;
  final String email;
  final String address;
  final DateTime start;
  final DateTime end;
  final String carId;
  final String carMake;
  final String carModel;
  final String carReg;
  final double pricePerDay;
  final double total;
  final DateTime createdAt;

  PrintLabel({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.phone,
    required this.email,
    required this.address,
    required this.start,
    required this.end,
    required this.carId,
    required this.carMake,
    required this.carModel,
    required this.carReg,
    required this.pricePerDay,
    required this.total,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
    'customerId': customerId,
    'customerName': customerName,
    'phone': phone,
    'email': email,
    'address': address,
    'start': Timestamp.fromDate(start),
    'end': Timestamp.fromDate(end),
    'carId': carId,
    'carMake': carMake,
    'carModel': carModel,
    'carReg': carReg,
    'pricePerDay': pricePerDay,
    'total': total,
    'createdAt': Timestamp.fromDate(createdAt),
  };

  factory PrintLabel.fromDoc(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return PrintLabel(
      id: doc.id,
      customerId: d['customerId'] as String,
      customerName: d['customerName'] as String,
      phone: d['phone'] as String,
      email: d['email'] as String? ?? '',
      address: d['address'] as String? ?? '',
      start: (d['start'] as Timestamp).toDate(),
      end: (d['end'] as Timestamp).toDate(),
      carId: d['carId'] as String,
      carMake: d['carMake'] as String,
      carModel: d['carModel'] as String,
      carReg: d['carReg'] as String,
      pricePerDay: (d['pricePerDay'] as num).toDouble(),
      total: (d['total'] as num).toDouble(),
      createdAt: (d['createdAt'] as Timestamp).toDate(),
    );
  }

  PrintLabel copyWith({
    String? id,
    // … other fields omitted for brevity …
    DateTime? createdAt,
  }) {
    return PrintLabel(
      id: id ?? this.id,
      customerId: customerId,
      customerName: customerName,
      phone: phone,
      email: email,
      address: address,
      start: start,
      end: end,
      carId: carId,
      carMake: carMake,
      carModel: carModel,
      carReg: carReg,
      pricePerDay: pricePerDay,
      total: total,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
