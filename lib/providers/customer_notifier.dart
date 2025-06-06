import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/customer_model.dart';
import '../screens/customer_search_screen.dart';


class CustomerFormState {
  final bool isLoading;
  final List<CustomerModel> matchingCustomers;
  final bool showForm;
  final String? error;

  CustomerFormState({
    this.isLoading = false,
    this.matchingCustomers = const [],
    this.showForm = false,
    this.error,
  });

  CustomerFormState copyWith({
    bool? isLoading,
    List<CustomerModel>? matchingCustomers,
    bool? showForm,
    String? error,
  }) {
    return CustomerFormState(
      isLoading: isLoading ?? this.isLoading,
      matchingCustomers: matchingCustomers ?? this.matchingCustomers,
      showForm: showForm ?? this.showForm,
      error: error ?? this.error,
    );
  }
}

final customerFormProvider = StateNotifierProvider<CustomerFormNotifier, CustomerFormState>((ref) {
  return CustomerFormNotifier(ref);
});

class CustomerFormNotifier extends StateNotifier<CustomerFormState> {
  final Ref ref;

  CustomerFormNotifier(this.ref) : super(CustomerFormState());

  Future<void> searchCustomers(String query) async {
    if (state.isLoading) return;

    debugPrint('[Notifier] Starting search...');
    state = state.copyWith(isLoading: true, error: null);

    try {
      final results = await ref.read(customerRepositoryProvider).searchCustomers(query);
      state = state.copyWith(
        isLoading: false,
        matchingCustomers: results,
        showForm: results.isEmpty,
      );
    } catch (e, stackTrace) {
      debugPrint('[Notifier] Search error: $e');
      debugPrint(stackTrace.toString());
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> createCustomer(CustomerModel customer) async {
    debugPrint('[Notifier] Creating customer...');
    state = state.copyWith(isLoading: true, error: null);

    try {
      await ref.read(customerRepositoryProvider).createCustomer(customer);
      state = state.copyWith(isLoading: false);
    } catch (e, stackTrace) {
      debugPrint('[Notifier] Create error: $e');
      debugPrint(stackTrace.toString());
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      rethrow;
    }
  }

  void resetForm() {
    debugPrint('[Notifier] Resetting form...');
    state = state.copyWith(
      matchingCustomers: [],
      showForm: false,
      error: null,
    );
  }
  Future<void> updateCustomer(CustomerModel customer) async {
    debugPrint('[Notifier] Updating customer...');
    state = state.copyWith(isLoading: true, error: null);

    try {
      await ref.read(customerRepositoryProvider).updateCustomer(customer);
      state = state.copyWith(isLoading: false);
    } catch (e, stackTrace) {
      debugPrint('[Notifier] Update error: $e');
      debugPrint(stackTrace.toString());
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      rethrow;
    }
  }

  void showForm() {
    state = state.copyWith(
      matchingCustomers: [],
      showForm: true,
      error: null,
    );
  }
}