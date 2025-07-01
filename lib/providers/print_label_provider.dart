import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/print_label_model.dart';

/// 1) The one true collection reference.
final printLabelCollectionProvider =
Provider<CollectionReference<Map<String, dynamic>>>(
      (ref) => FirebaseFirestore.instance
      .collection('rentalLabels'),  // <-- make sure this matches everywhere
);

/// 2) Stream all labels *for this customer*, ordered by creation.
final printLabelsForCustomerProvider =
StreamProvider.family<List<PrintLabel>, String>(
      (ref, customerId) {
    final col = ref.watch(printLabelCollectionProvider);
    return col
        .where('customerId', isEqualTo: customerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
        .map((d) => PrintLabel.fromDoc(d))
        .toList());
  },
);
