// lib/models/transfer_query.dart

import 'transfer_type.dart';

/// A Firestore query for transfers of a given type, between [start] and [end].
class TransferQuery {
  final TransferType type;
  final DateTime start;
  final DateTime end;

  const TransferQuery({
    required this.type,
    required this.start,
    required this.end,
  });

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is TransferQuery &&
            runtimeType == other.runtimeType &&
            type == other.type &&
            start == other.start &&
            end == other.end;
  }

  @override
  int get hashCode => Object.hash(type, start, end);
}
