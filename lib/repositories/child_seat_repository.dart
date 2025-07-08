import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/child_seat_model.dart';
import '../models/transfer_model.dart';

class ChildSeatRepository {
  final CollectionReference<Map<String, dynamic>> _seatsCol =
  FirebaseFirestore.instance.collection('childSeats');
  final CollectionReference<Map<String, dynamic>> _transfersCol =
  FirebaseFirestore.instance.collection('transfers');

  /// Fetch all child‐seat definitions.
  Future<List<ChildSeat>> getAllSeats() async {
    final snap = await _seatsCol.get();
    return snap.docs.map((d) => ChildSeat.fromDoc(d)).toList();
  }

  /// Return the set of seat IDs already reserved by any transfer
  /// whose [start] < requestedEnd AND [end] > requestedStart.
  Future<Set<String>> _busySeatIds(
      DateTime requestedStart, DateTime requestedEnd) async {
    final startTs = Timestamp.fromDate(requestedStart);
    final endTs   = Timestamp.fromDate(requestedEnd);

    final snap = await _transfersCol
    // only consider non‐canceled transfers
        .where('status', whereIn: [
      TransferStatus.pending.name,
      TransferStatus.confirmed.name,
      TransferStatus.completed.name,
    ])
        .where('start', isLessThan: endTs)
        .where('end',   isGreaterThan: startTs)
        .get();

    final busy = <String>{};
    for (final doc in snap.docs) {
      final data = doc.data();
      final seats = (data['childSeatIds'] as List<dynamic>?)
          ?.cast<String>() ??
          [];
      busy.addAll(seats);
    }
    return busy;
  }

  /// Returns only those seats that are _not_ busy in the given local
  /// date‐range.
  Future<List<ChildSeat>> getAvailableSeats(
      DateTime localStart, DateTime localEnd) async {
    final all     = await getAllSeats();
    final busyIds = await _busySeatIds(localStart, localEnd);
    return all.where((s) => !busyIds.contains(s.id)).toList();
  }
}
