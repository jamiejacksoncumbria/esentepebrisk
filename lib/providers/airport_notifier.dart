// lib/providers/airport_notifier.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/airport_model.dart';
import '../repositories/airport_repository.dart';

/// Expose the repo
final airportRepositoryProvider = Provider<AirportRepository>((ref) {
  return AirportRepository();
});

/// Stream of existing airports (if you ever need to list them)
final airportsStreamProvider = StreamProvider<List<Airport>>((ref) {
  final repo = ref.watch(airportRepositoryProvider);
  return repo.getAirports();
});

/// StateNotifier to manage “add airport” calls
final airportNotifierProvider =
StateNotifierProvider<AirportNotifier, AsyncValue<void>>((ref) {
  return AirportNotifier(ref.watch(airportRepositoryProvider));
});

class AirportNotifier extends StateNotifier<AsyncValue<void>> {
  final AirportRepository _repo;
  AirportNotifier(this._repo) : super(const AsyncData(null));

  Future<void> addAirport(String name, String code) async {
    state = const AsyncLoading();
    try {
      final airport = Airport(id: '', name: name, code: code);
      await _repo.addAirport(airport);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
  Future<void> updateAirport(String id, String name, String code) async {
    state = const AsyncLoading();
    try {
      final airport = Airport(id: id, name: name, code: code);
      await _repo.updateAirport(airport);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
  Future<void> deleteAirport(String id) async {
    state = const AsyncLoading();
    try {
      await _repo.deleteAirport(id);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}
