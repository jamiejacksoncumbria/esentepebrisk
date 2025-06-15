// 1: Repository provider
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/staff_model.dart';
import '../repositories/staff_repository.dart';

final staffRepoProvider = Provider((ref) => StaffRepository());

// 2: StreamProvider for the staff list
final staffListProvider = StreamProvider<List<Staff>>((ref) {
  final repo = ref.watch(staffRepoProvider);
  return repo.streamStaff();
});