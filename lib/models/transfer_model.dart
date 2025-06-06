import 'dart:ffi';

import 'package:cloud_firestore/cloud_firestore.dart';

class TransferModel {
  String? collectionUUID;
  String? customerUUID;
  Timestamp? collectionDateAndTime;
  Timestamp? flightDateAndTime;
  String? collectionDateAndTimeString;
  String? flightDateAndTimeString;
  String? pickupLocation;
  String? dropOffLocation;
  Bool? airportCollection;
  String? amountOfPeople;
  String? cost;
  String? driver;
  String? driverUUID;
  GeoPoint? pickupLocationGeoPoint;
  GeoPoint? dropOffLocationGeoPoint;

  TransferModel.airport({
    required this.collectionUUID,
    required this.customerUUID,
    required this.collectionDateAndTime,
    required this.flightDateAndTime,
    required this.collectionDateAndTimeString,
    required this.flightDateAndTimeString,
    required this.pickupLocation,
    required this.dropOffLocation,
    required this.airportCollection,
    required this.amountOfPeople,
    required this.cost,
    required this.driver,
    required this.driverUUID,
    required this.pickupLocationGeoPoint,
    required this.dropOffLocationGeoPoint,
  });

  TransferModel.noneAirport({
    required this.collectionUUID,
    required this.customerUUID,
    required this.collectionDateAndTime,
    this.flightDateAndTime,
    required this.collectionDateAndTimeString,
    required this.flightDateAndTimeString,
    required this.pickupLocation,
    required this.dropOffLocation,
    required this.airportCollection,
    required this.amountOfPeople,
    required this.cost,
    required this.driver,
    required this.driverUUID,
    this.pickupLocationGeoPoint,
    this.dropOffLocationGeoPoint,
  });

  Map<String, dynamic> toMap() {
    return {
      'collectionUUID': collectionUUID,
      'customerUUID': customerUUID,
      'collectionDateAndTime': collectionDateAndTime,
      'flightDateAndTime': flightDateAndTime,
      'collectionDateAndTimeString': collectionDateAndTimeString,
      'flightDateAndTimeString': flightDateAndTimeString,
      'pickupLocation': pickupLocation,
      'dropOffLocation': dropOffLocation,
      'airportCollection': airportCollection,
      'amountOfPeople': amountOfPeople,
      'cost': cost,
      'driver': driver,
      'driverUUID': driverUUID,
      'pickupLocationGeoPoint': pickupLocationGeoPoint,
      'dropOffLocationGeoPoint': dropOffLocationGeoPoint,
    };
  }

  factory TransferModel.fromMap(Map<String, dynamic> map) {
    return TransferModel.airport(
      collectionUUID: map['collectionUUID'] as String,
      customerUUID: map['customerUUID'] as String,
      collectionDateAndTime: map['collectionDateAndTime'] as Timestamp,
      flightDateAndTime: map['flightDateAndTime'] as Timestamp,
      collectionDateAndTimeString: map['collectionDateAndTimeString'] as String,
      flightDateAndTimeString: map['flightDateAndTimeString'] as String,
      pickupLocation: map['pickupLocation'] as String,
      dropOffLocation: map['dropOffLocation'] as String,
      airportCollection: map['airportCollection'] as Bool,
      amountOfPeople: map['amountOfPeople'] as String,
      cost: map['cost'] as String,
      driver: map['driver'] as String,
      driverUUID: map['driverUUID'] as String,
      pickupLocationGeoPoint: map['pickupLocationGeoPoint'] as GeoPoint,
      dropOffLocationGeoPoint: map['dropOffLocationGeoPoint'] as GeoPoint,

    );
  }
}
