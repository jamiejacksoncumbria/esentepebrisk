import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/transfer_query.dart';
import '../models/transfer_model.dart';
import '../repositories/transfer_repository.dart';

/// repository
final transferRepoProvider = Provider((_) => TransferRepository());

/// Stream transfers by any query
final transfersByQueryProvider =
StreamProvider.family<List<TransferModel>, TransferQuery>((ref, query) {
  return ref.watch(transferRepoProvider).streamByQuery(query);
});
