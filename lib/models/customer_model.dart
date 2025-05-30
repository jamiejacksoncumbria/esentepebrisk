import 'dart:ffi';

import 'package:cloud_firestore/cloud_firestore.dart';

class CustomerModel {
  String? customerUUID;
  String? firstName;
  String? surName;
  String? phoneNumber;
  String? phoneNumber2;
  String? email;

  CustomerModel({required this.customerUUID, required this.firstName, required this.surName,
    required this.phoneNumber, this.phoneNumber2, this.email});

}
