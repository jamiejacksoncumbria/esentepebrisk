import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/driver_model.dart';
import '../repositories/driver_repository.dart';

/// Stream of drivers
final driversStreamProvider =
StreamProvider.autoDispose<List<Driver>>((ref) {
  return DriverRepository().streamDrivers();
});

/// StateNotifier for add/update/delete
class DriverNotifier extends StateNotifier<bool> {
  DriverNotifier(this._repo): super(false);
  final DriverRepository _repo;

  Future<void> addDriver(Driver d) async {
    state = true;
    try {
      await _repo.addDriver(d);
    } finally {
      state = false;
    }
  }

  Future<void> updateDriver(Driver d) async {
    state = true;
    try {
      await _repo.updateDriver(d);
    } finally {
      state = false;
    }
  }

  Future<void> deleteDriver(String id) async {
    state = true;
    try {
      await _repo.deleteDriver(id);
    } finally {
      state = false;
    }
  }
}

final driverNotifierProvider =
StateNotifierProvider<DriverNotifier, bool>((ref) {
  return DriverNotifier(DriverRepository());
});
