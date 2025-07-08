// lib/models/transfer_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'transfer_type.dart';

/// The possible states of a transfer.
enum TransferStatus { pending, confirmed, canceled, completed }

class TransferModel {
  final String   collectionUUID;
  final String   customerUUID;
  final TransferType type;
  final Timestamp    collectionDateAndTime;

  // optional flight info
  final String?  flightNumber;
  final Timestamp? flightDateAndTime;

  // pickup/drop-off
  final String   pickupLocation;
  final String   dropOffLocation;
  final bool?    airportCollection;

  // snapshot of customer details at booking time
  final String   customerName;
  final String   phone1;
  final String?  phone2;

  // who booked it
  final String   staffId;
  final String   staffName;

  // assigned driver info
  final String   driverUUID;
  final String   driverName;

  final String   amountOfPeople;
  final String   cost;

  // optional geodata
  final GeoPoint? pickupLocationGeoPoint;
  final GeoPoint? dropOffLocationGeoPoint;

  final String?  notes;

  final List<String>? childSeatIds;
  final List<String>? childAges;

  final int      adults;
  final int      children;
  final TransferStatus status;

  TransferModel({
    required this.collectionUUID,
    required this.customerUUID,
    required this.type,
    required this.collectionDateAndTime,

    this.flightNumber,
    this.flightDateAndTime,

    required this.pickupLocation,
    required this.dropOffLocation,
    this.airportCollection,

    required this.customerName,
    required this.phone1,
    this.phone2,

    required this.staffId,
    required this.staffName,

    required this.driverUUID,
    required this.driverName,

    required this.amountOfPeople,
    required this.cost,

    this.pickupLocationGeoPoint,
    this.dropOffLocationGeoPoint,

    this.notes,

    this.childSeatIds,
    this.childAges,

    this.adults = 1,
    this.children = 0,
    this.status = TransferStatus.pending,
  });

  Map<String, dynamic> toMap() {
    return {
      'collectionUUID': collectionUUID,
      'customerUUID':   customerUUID,
      'type':           type.name,
      'collectionDateAndTime': collectionDateAndTime,

      if (flightNumber        != null) 'flightNumber':        flightNumber,
      if (flightDateAndTime   != null) 'flightDateAndTime':   flightDateAndTime,

      'pickupLocation':      pickupLocation,
      'dropOffLocation':     dropOffLocation,
      'airportCollection':   airportCollection,

      'customerName':        customerName,
      'phone1':              phone1,
      if (phone2             != null) 'phone2':             phone2,

      'staffId':             staffId,
      'staffName':           staffName,

      'driverUUID':          driverUUID,
      'driverName':          driverName,

      'amountOfPeople':      amountOfPeople,
      'cost':                cost,

      if (pickupLocationGeoPoint != null)
        'pickupLocationGeoPoint': pickupLocationGeoPoint,
      if (dropOffLocationGeoPoint != null)
        'dropOffLocationGeoPoint': dropOffLocationGeoPoint,

      if (notes              != null) 'notes':              notes,
      if (childSeatIds       != null) 'childSeatIds':       childSeatIds,
      if (childAges          != null) 'childAges':          childAges,

      'adults':              adults,
      'children':            children,
      'status':              status.name,
    };
  }

  factory TransferModel.fromMap(Map<String, dynamic> map) {
    final status = TransferStatus.values.firstWhere(
          (e) => e.name == (map['status'] as String? ?? 'pending'),
      orElse: () => TransferStatus.pending,
    );

    final type = TransferType.values.firstWhere(
          (e) => e.name == (map['type'] as String? ?? 'other'),
      orElse: () => TransferType.other,
    );

    return TransferModel(
      collectionUUID:       map['collectionUUID'] as String,
      customerUUID:         map['customerUUID'] as String,
      type:                 type,
      collectionDateAndTime: map['collectionDateAndTime'] as Timestamp,

      flightNumber:         map['flightNumber'] as String?,
      flightDateAndTime:    map['flightDateAndTime'] as Timestamp?,

      pickupLocation:       map['pickupLocation'] as String,
      dropOffLocation:      map['dropOffLocation'] as String,
      airportCollection:    map['airportCollection'] as bool?,

      customerName:         map['customerName'] as String? ?? '',
      phone1:               map['phone1'] as String? ?? '',
      phone2:               map['phone2'] as String?,

      staffId:              map['staffId'] as String? ?? '',
      staffName:            map['staffName'] as String? ?? '',

      driverUUID:           map['driverUUID'] as String? ?? '',
      driverName:           map['driverName'] as String? ?? '',

      amountOfPeople:       map['amountOfPeople'] as String? ?? '',
      cost:                 map['cost'] as String? ?? '',

      pickupLocationGeoPoint: map['pickupLocationGeoPoint'] as GeoPoint?,
      dropOffLocationGeoPoint: map['dropOffLocationGeoPoint'] as GeoPoint?,

      notes:                map['notes'] as String?,

      childSeatIds: map['childSeatIds'] != null
          ? List<String>.from(map['childSeatIds'] as List<dynamic>)
          : null,

      childAges:   map['childAges'] != null
          ? List<String>.from(map['childAges'] as List<dynamic>)
          : null,

      adults:     map['adults'] as int? ?? 1,
      children:   map['children'] as int? ?? 0,
      status:     status,
    );
  }
}
