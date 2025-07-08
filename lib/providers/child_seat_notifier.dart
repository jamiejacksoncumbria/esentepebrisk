// lib/providers/child_seat_notifier.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/child_seat_model.dart';

/// A Firestore-backed repository for simple CRUD on child seats.
class ChildSeatRepository {
  final _col = FirebaseFirestore.instance
      .collection('childSeats')
      .withConverter<ChildSeat>(
    fromFirestore: (snap, _) => ChildSeat.fromDoc(snap),
    toFirestore: (seat, _) => seat.toMap(),
  );

  /// Stream all seats, real-time.
  Stream<List<ChildSeat>> streamSeats() {
    return _col.snapshots().map(
          (snap) => snap.docs.map((d) => d.data()).toList(),
    );
  }

  /// Add a new seat.
  Future<void> addSeat(String type, String age) {
    final seat = ChildSeat(id: '', type: type, age: age);
    return _col.add(seat);
  }

  /// Update an existing seat.
  Future<void> updateSeat(String id, String type, String age) {
    final seat = ChildSeat(id: id, type: type, age: age);
    return _col.doc(id).set(seat);
  }

  /// Delete a seat.
  Future<void> deleteSeat(String id) {
    return _col.doc(id).delete();
  }
}

/// Expose the repository
final childSeatRepositoryProvider = Provider<ChildSeatRepository>((ref) {
  return ChildSeatRepository();
});

/// A real-time list of all seats
final childSeatsStreamProvider = StreamProvider<List<ChildSeat>>((ref) {
  final repo = ref.watch(childSeatRepositoryProvider);
  return repo.streamSeats();
});

/// StateNotifier for add/update/delete calls
final childSeatNotifierProvider =
StateNotifierProvider<ChildSeatNotifier, AsyncValue<void>>((ref) {
  return ChildSeatNotifier(ref.watch(childSeatRepositoryProvider));
});

class ChildSeatNotifier extends StateNotifier<AsyncValue<void>> {
  final ChildSeatRepository _repo;
  ChildSeatNotifier(this._repo) : super(const AsyncData(null));

  Future<void> addChildSeat(String type, String age) async {
    state = const AsyncLoading();
    try {
      await _repo.addSeat(type, age);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> updateChildSeat(String id, String type, String age) async {
    state = const AsyncLoading();
    try {
      await _repo.updateSeat(id, type, age);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> deleteChildSeat(String id) async {
    state = const AsyncLoading();
    try {
      await _repo.deleteSeat(id);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}
