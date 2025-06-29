// lib/providers/car_video_provider.dart

import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/car_video_model.dart';
import '../repositories/car_video_repository.dart';

/// Provides a singleton CarVideoRepository.
final carVideoRepoProvider = Provider<CarVideoRepository>((ref) {
  return CarVideoRepository();
});

/// Streams the list of CarVideo for a given customerId,
/// logs any errors to the console in debug mode.
final carVideosForCustomerProvider =
StreamProvider.family<List<CarVideo>, String>((ref, custId) {
  return ref
      .watch(carVideoRepoProvider)
      .streamForCustomer(custId)
      .handleError((error, stack) {
    if (kDebugMode) {
      debugPrint(
        '[carVideosForCustomerProvider] '
            'customerId=$custId error: $error\n$stack',
      );
    }
  });
});
