// lib/repositories/car_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/car_model.dart';

class CarRepository {
  final FirebaseFirestore _firestore;
  CarRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference get _col => _firestore.collection('cars');

  Future<void> addCar(Car car) {
    return _col.add(car.toMap());
  }

  Future<void> updateCar(Car car) {
    return _col.doc(car.id).update(car.toMap());
  }

  Stream<List<Car>> getCars() {
    return _col.snapshots().map((snap) =>
        snap.docs.map((d) => Car.fromDoc(d)).toList());
  }
  Future<void> deleteCar(String id) {
    return _col.doc(id).delete();
  }
}
