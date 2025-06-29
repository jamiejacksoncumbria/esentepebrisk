import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/child_seat_model.dart';
import '../repositories/child_seat_repository.dart';

// 1) StreamProvider for the list of seats
final childSeatsStreamProvider =
StreamProvider.autoDispose<List<ChildSeat>>((ref) {
  return ChildSeatRepository().streamChildSeats();
});

// 2) StateNotifier for loading state & CRUD
class ChildSeatNotifier extends StateNotifier<bool> {
  ChildSeatNotifier(this._repo) : super(false);
  final ChildSeatRepository _repo;

  Future<void> addChildSeat(String type, String age) async {
    state = true;
    try {
      await _repo.addChildSeat(type, age);
    } finally {
      state = false;
    }
  }

  Future<void> updateChildSeat(String id, String type, String age) async {
    state = true;
    try {
      await _repo.updateChildSeat(id, type, age);
    } finally {
      state = false;
    }
  }

  Future<void> deleteChildSeat(String id) async {
    state = true;
    try {
      await _repo.deleteChildSeat(id);
    } finally {
      state = false;
    }
  }
}

final childSeatNotifierProvider =
StateNotifierProvider<ChildSeatNotifier, bool>((ref) {
  return ChildSeatNotifier(ChildSeatRepository());
});
