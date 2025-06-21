// lib/providers/car_notifier.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/car_model.dart';
import '../repositories/car_repository.dart';

final carRepositoryProvider = Provider<CarRepository>((ref) {
  return CarRepository();
});

final carsStreamProvider = StreamProvider<List<Car>>((ref) {
  return ref.watch(carRepositoryProvider).getCars();
});

final carNotifierProvider =
StateNotifierProvider<CarNotifier, AsyncValue<void>>((ref) {
  return CarNotifier(ref.watch(carRepositoryProvider));
});

class CarNotifier extends StateNotifier<AsyncValue<void>> {
  final CarRepository _repo;
  CarNotifier(this._repo) : super(const AsyncData(null));

  Future<void> addCar(String make, String model, String reg) async {
    state = const AsyncLoading();
    try {
      final car = Car(id: '', make: make, model: model, registration: reg);
      await _repo.addCar(car);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> updateCar(String id, String make, String model, String reg) async {
    state = const AsyncLoading();
    try {
      final car = Car(id: id, make: make, model: model, registration: reg);
      await _repo.updateCar(car);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
  Future<void> deleteCar(String id) async {
    state = const AsyncLoading();
    try {
      await _repo.deleteCar(id);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}
