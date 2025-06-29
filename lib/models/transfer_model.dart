// lib/models/transfer_model.dart

import 'dart:ffi';
import 'package:cloud_firestore/cloud_firestore.dart';

/// The possible states of a transfer.
enum TransferStatus { pending, confirmed, canceled, completed }

class TransferModel {
  String? collectionUUID;
  String? customerUUID;
  Timestamp? collectionDateAndTime;
  Timestamp? flightDateAndTime;
  String? pickupLocation;
  String? dropOffLocation;
  Bool? airportCollection;
  String? amountOfPeople;
  String? cost;
  String? driverUUID;
  GeoPoint? pickupLocationGeoPoint;
  GeoPoint? dropOffLocationGeoPoint;
  String? notes;

  /// IDs of selected child‐seat documents
  List<String>? childSeatIds;

  /// Number of adults on this transfer
  int adults;

  /// Number of children on this transfer
  int children;

  /// Current status of the transfer
  TransferStatus status;

  TransferModel.airport({
    required this.collectionUUID,
    required this.customerUUID,
    required this.collectionDateAndTime,
    required this.flightDateAndTime,
    required this.pickupLocation,
    required this.dropOffLocation,
    required this.airportCollection,
    required this.amountOfPeople,
    required this.cost,
    required this.driverUUID,
    required this.pickupLocationGeoPoint,
    required this.dropOffLocationGeoPoint,
    required this.notes,
    this.childSeatIds,
    this.adults = 1,
    this.children = 0,
    this.status = TransferStatus.pending,
  });

  TransferModel.noneAirport({
    required this.collectionUUID,
    required this.customerUUID,
    required this.collectionDateAndTime,
    required this.notes,
    this.flightDateAndTime,
    required this.pickupLocation,
    required this.dropOffLocation,
    required this.airportCollection,
    required this.amountOfPeople,
    required this.cost,
    required this.driverUUID,
    this.pickupLocationGeoPoint,
    this.dropOffLocationGeoPoint,
    this.childSeatIds,
    this.adults = 1,
    this.children = 0,
    this.status = TransferStatus.pending,
  });

  Map<String, dynamic> toMap() {
    final m = <String, dynamic>{
      'collectionUUID': collectionUUID,
      'customerUUID': customerUUID,
      'collectionDateAndTime': collectionDateAndTime,
      'flightDateAndTime': flightDateAndTime,
      'pickupLocation': pickupLocation,
      'dropOffLocation': dropOffLocation,
      'airportCollection': airportCollection,
      'amountOfPeople': amountOfPeople,
      'cost': cost,
      'notes': notes,
      'driverUUID': driverUUID,
      'pickupLocationGeoPoint': pickupLocationGeoPoint,
      'dropOffLocationGeoPoint': dropOffLocationGeoPoint,

      // new fields
      'adults': adults,
      'children': children,
      'status': status.name,
    };
    if (childSeatIds != null) {
      m['childSeatIds'] = childSeatIds;
    }
    return m;
  }

  factory TransferModel.fromMap(Map<String, dynamic> map) {
    final seats = map['childSeatIds'] != null
        ? List<String>.from(map['childSeatIds'] as List<dynamic>)
        : null;

    // parse status string back into enum
    final statusStr = map['status'] as String? ?? 'pending';
    final status = TransferStatus.values.firstWhere(
          (e) => e.name == statusStr,
      orElse: () => TransferStatus.pending,
    );

    return TransferModel.airport(
      collectionUUID: map['collectionUUID'] as String?,
      customerUUID: map['customerUUID'] as String?,
      collectionDateAndTime: map['collectionDateAndTime'] as Timestamp?,
      flightDateAndTime: map['flightDateAndTime'] as Timestamp?,

      pickupLocation: map['pickupLocation'] as String?,
      dropOffLocation: map['dropOffLocation'] as String?,
      airportCollection: map['airportCollection'] as Bool?,
      amountOfPeople: map['amountOfPeople'] as String?,
      cost: map['cost'] as String?,
      notes: map['notes'] as String?,
      driverUUID: map['driverUUID'] as String?,
      pickupLocationGeoPoint:
      map['pickupLocationGeoPoint'] as GeoPoint?,
      dropOffLocationGeoPoint:
      map['dropOffLocationGeoPoint'] as GeoPoint?,
      childSeatIds: seats,
      adults: map['adults'] as int? ?? 1,
      children: map['children'] as int? ?? 0,
      status: status,
    );
  }
}
