import 'dart:ffi';

import 'package:cloud_firestore/cloud_firestore.dart';

class TransferModel {
  String? uuid;
  Timestamp? collectionDateAndTime;
  Timestamp? flightDateAndTime;
  String? dateString;
  String? timeString;
  String? firstName;
  String? surName;
  String? pickupLocation;
  String? dropOffLocation;
  String? phoneNumber;
  String? phoneNumber2;
  String? email;
  Bool? airportCollection;
  String? amountOfPeople;
  String? cost;
  String? driver;
  String? driverUUID;
  GeoPoint? pickupLocationGeoPoint;
  GeoPoint? dropOffLocationGeoPoint;

  TransferModel.airport({required this.uuid, required this.collectionDateAndTime, required this.flightDateAndTime,
    required this.dateString, required this.timeString, required this.firstName, required this.surName,
    required this.pickupLocation, required this.dropOffLocation, required this.phoneNumber,
    this.phoneNumber2, this.email, required this.airportCollection,
    required this.amountOfPeople, required this.cost, required this.driver, required this.driverUUID,
    this.pickupLocationGeoPoint, this.dropOffLocationGeoPoint});

  TransferModel.noneAirport({required this.uuid, required this.collectionDateAndTime,
    this.flightDateAndTime, required this.dateString, required this.timeString, required this.firstName,
    required this.surName, required this.pickupLocation, required this.dropOffLocation, required this.phoneNumber,
    this.phoneNumber2, this.email, required this.airportCollection,
    required this.amountOfPeople, required this.cost, required this.driver, required this.driverUUID,
    this.pickupLocationGeoPoint, this.dropOffLocationGeoPoint});


}
