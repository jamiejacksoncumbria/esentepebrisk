// lib/repositories/airport_repository.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/airport_model.dart';

class AirportRepository {
  final FirebaseFirestore _firestore;

  AirportRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference get _col => _firestore.collection('airPorts');

  /// Adds a new airport document.
  Future<void> addAirport(Airport airport) {
    return _col.add(airport.toMap());
  }

  /// Streams airports ordered by name.
  ///
  /// Make sure you’ve created an index on the 'name' field in Firestore console.
  Stream<List<Airport>> getAirports() {
    return _col
        .orderBy('name')
        .snapshots()
        .map((snap) =>
        snap.docs.map((d) => Airport.fromDoc(d)).toList());
  }

  /// Updates an existing airport document.
  Future<void> updateAirport(Airport airport) {
    return _col.doc(airport.id).update(airport.toMap());
  }

  /// Deletes an airport document.
  Future<void> deleteAirport(String id) {
    return _col.doc(id).delete();
  }
}
