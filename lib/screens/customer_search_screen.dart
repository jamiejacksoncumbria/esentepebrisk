import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/customer_model.dart';
import '../repositories/customer_repository.dart';
import 'customer_form_screen.dart';

final customerRepositoryProvider = Provider((ref) => CustomerRepository());

class CustomerSearchScreen extends ConsumerStatefulWidget {
  const CustomerSearchScreen({super.key});

  @override
  ConsumerState<CustomerSearchScreen> createState() => _CustomerSearchScreenState();
}

class _CustomerSearchScreenState extends ConsumerState<CustomerSearchScreen> {
  final _searchController = TextEditingController();
  bool _isLoading = false;
  List<CustomerModel> _searchResults = [];
  bool _showForm = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchCustomers() async {
    if (_searchController.text.length < 3) {
      setState(() {
        _searchResults = [];
        _showForm = false;
      });
      return;
    }

    setState(() => _isLoading = true);
    try {
      final results = await ref.read(customerRepositoryProvider)
          .searchCustomers(_searchController.text);

      setState(() {
        _searchResults = results;
        _showForm = results.isEmpty;
      });
    } catch (e) {
      if(mounted){ ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Search failed: ${e.toString()}')),
      );}

    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteCustomer(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Are you sure you want to delete this customer and all their photos?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);
      try {
        await ref.read(customerRepositoryProvider).deleteCustomer(id);
        _searchCustomers(); // Refresh results
      } catch (e) {
        if(mounted){ ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Delete failed: ${e.toString()}')),
        );}

      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer Search'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              setState(() {
                _searchResults = [];
                _showForm = true;
                _searchController.clear();
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search by name, phone, or email',
                suffixIcon: _isLoading
                    ? const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                    : IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: _searchCustomers,
                ),
              ),
              onChanged: (_) => _searchCustomers(),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _showForm
                ? CustomerFormScreen(
              onSave: _searchCustomers,
            )
                : _searchResults.isEmpty
                ? const Center(child: Text('No customers found. Type to search or click + to add.'))
                : ListView.builder(
              itemCount: _searchResults.length,
              itemBuilder: (context, index) {
                final customer = _searchResults[index];
                return GestureDetector(
                  onLongPress: () => _deleteCustomer(customer.id),
                  child: Card(
                    margin: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 4),
                    child: ListTile(
                      title: Text(
                          '${customer.firstName} ${customer.lastName}'),
                      subtitle: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          Text(customer.phone),
                          if (customer.secondaryPhone != null)
                            Text('Secondary: ${customer.secondaryPhone}'),
                          if (customer.email != null)
                            Text(customer.email!),
                        ],
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CustomerFormScreen(
                              customer: customer,
                              onSave: _searchCustomers,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}