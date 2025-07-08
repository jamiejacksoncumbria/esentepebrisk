import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/car_video_model.dart';
import '../repositories/car_video_repository.dart';

final carVideoRepoProvider = Provider((_) => CarVideoRepository());

// existing:
final carVideosForCustomerProvider =
StreamProvider.family<List<CarVideo>, String>((ref, custId) {
  return ref.watch(carVideoRepoProvider).streamForCustomer(custId);
});

// NEW: family for date‐range queries
class DateRange {
  final DateTime start, end;
  DateRange({required this.start, required this.end});
  @override
  bool operator ==(Object o) =>
      o is DateRange && o.start == start && o.end == end;
  @override
  int get hashCode => start.hashCode ^ end.hashCode;
}

final carVideosBetweenDatesProvider =
StreamProvider.family<List<CarVideo>, DateRange>((ref, range) {
  return ref
      .watch(carVideoRepoProvider)
      .streamBetweenDates(range.start, range.end);
});
