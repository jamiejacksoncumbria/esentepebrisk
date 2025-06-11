import 'package:cloud_firestore/cloud_firestore.dart';

class CustomerModel {
  final String id;
  final String firstName;
  final String lastName;
  final String phone;
  final String? secondaryPhone;
  final String? email;
  final String? address;
  final GeoPoint? location;
  String? passportPhotoUrl;
  String? licensePhotoUrl;
  final List<String> searchTerms;
  final Timestamp createdAt;

  CustomerModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.phone,
    this.secondaryPhone,
    this.email,
    this.address,
    this.location,
    this.passportPhotoUrl,
    this.licensePhotoUrl,
    required this.searchTerms,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'firstName': firstName,
      'lastName': lastName,
      'phone': phone,
      if (secondaryPhone != null) 'secondaryPhone': secondaryPhone,
      if (email != null) 'email': email,
      if (address != null) 'address': address,
      if (location != null) 'location': location,
      if (passportPhotoUrl != null) 'passportPhotoUrl': passportPhotoUrl,
      if (licensePhotoUrl != null) 'licensePhotoUrl': licensePhotoUrl,
      'searchTerms': searchTerms,
      'createdAt': createdAt,
    };
  }

  factory CustomerModel.fromMap(Map<String, dynamic> map) {
    return CustomerModel(
      id: map['id'] as String,
      firstName: map['firstName'] as String,
      lastName: map['lastName'] as String,
      phone: map['phone'] as String,
      secondaryPhone: map['secondaryPhone'] as String?,
      email: map['email'] as String?,
      address: map['address'] as String?,
      location: map['location'] as GeoPoint?,
      passportPhotoUrl: map['passportPhotoUrl'] as String?,
      licensePhotoUrl: map['licensePhotoUrl'] as String?,
      searchTerms: List<String>.from(map['searchTerms'] as List),
      createdAt: map['createdAt'] as Timestamp,
    );
  }

  CustomerModel copyWith({
    String? id,
    String? firstName,
    String? lastName,
    String? phone,
    String? secondaryPhone,
    String? email,
    String? address,
    GeoPoint? location,
    String? passportPhotoUrl,
    String? licensePhotoUrl,
    List<String>? searchTerms,
    Timestamp? createdAt,
  }) {
    return CustomerModel(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      phone: phone ?? this.phone,
      secondaryPhone: secondaryPhone ?? this.secondaryPhone,
      email: email ?? this.email,
      address: address ?? this.address,
      location: location ?? this.location,
      passportPhotoUrl: passportPhotoUrl ?? this.passportPhotoUrl,
      licensePhotoUrl: licensePhotoUrl ?? this.licensePhotoUrl,
      searchTerms: searchTerms ?? this.searchTerms,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}