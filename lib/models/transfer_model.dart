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
    this.pickupLocationGeoPoint,
    this.dropOffLocationGeoPoint,
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
}
