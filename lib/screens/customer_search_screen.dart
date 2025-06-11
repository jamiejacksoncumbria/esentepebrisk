import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/customer_model.dart';
import '../repositories/customer_repository.dart';
import '../utils/customer_utils.dart';
import 'customer_form_screen.dart';


final customerRepositoryProvider = Provider((ref) => CustomerRepository());

class CustomerSearchScreen extends ConsumerStatefulWidget {
  final String? searchTerm;

  const CustomerSearchScreen({super.key, this.searchTerm});

  @override
  ConsumerState<CustomerSearchScreen> createState() =>
      _CustomerSearchScreenState();
}

class _CustomerSearchScreenState extends ConsumerState<CustomerSearchScreen> {
  late final TextEditingController _searchController;
  bool _isLoading = false;
  List<CustomerModel> _searchResults = [];
  bool _showForm = false;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.searchTerm);
    if (widget.searchTerm != null && widget.searchTerm!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _searchCustomers();
      });
    }
  }

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
      final results = await ref
          .read(customerRepositoryProvider)
          .searchCustomers(_searchController.text);

      setState(() {
        _searchResults = results;
        _showForm = results.isEmpty;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Search failed: ${e.toString()}')),
        );
      }
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
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);
      try {
        await ref.read(customerRepositoryProvider).deleteCustomer(id);
        _searchCustomers();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Delete failed: ${e.toString()}')),
          );
        }
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final cleaned = sanitizePhoneNumber(phoneNumber);
    final url = Uri.parse('tel:$cleaned');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch phone app')),
        );
      }
    }
  }

  Future<void> _sendSms(String phoneNumber) async {
    final cleaned = sanitizePhoneNumber(phoneNumber);
    final url = Uri.parse('sms:$cleaned');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch messaging app')),
        );
      }
    }
  }

  Future<void> _openWhatsApp(String phoneNumber) async {
    final cleaned = sanitizePhoneNumber(phoneNumber).replaceAll('+', '');
    final url = Uri.parse('https://wa.me/$cleaned');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch WhatsApp')),
        );
      }
    }
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    Color? color,
    Color? textColor = Colors.white,
  }) {
    return ElevatedButton.icon(
      icon: Icon(icon, size: 16, color: textColor),
      label: Text(label, style: TextStyle(color: textColor)),
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        textStyle: const TextStyle(fontSize: 12),
        backgroundColor: color,
        foregroundColor: textColor,
      ),
    );
  }

  Widget _buildPhoneActions(String phoneNumber) {
    final List<Widget> buttons = [];

    buttons.add(
      _buildActionButton(
        icon: Icons.chat,
        label: 'WhatsApp Msg',
        onPressed: () => _openWhatsApp(phoneNumber),
        color: Colors.green[700],
      ),
    );

    buttons.add(
      _buildActionButton(
        icon: Icons.phone,
        label: 'WhatsApp Call',
        onPressed: () => _openWhatsApp(phoneNumber),
        color: Colors.green[900],
      ),
    );

    if (kIsWeb || Platform.isAndroid || Platform.isIOS) {
      buttons.add(
        _buildActionButton(
          icon: Icons.call,
          label: 'Call',
          onPressed: () => _makePhoneCall(phoneNumber),
          color: Colors.green,
        ),
      );
    }

    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      buttons.add(
        _buildActionButton(
          icon: Icons.message,
          label: 'SMS',
          onPressed: () => _sendSms(phoneNumber),
          color: Colors.blue,
        ),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: buttons,
    );
  }

  Widget _buildTransferButtons(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 800;
        return isWide ? _buildButtonRow() : _buildButtonColumn();
      },
    );
  }

  Widget _buildButtonRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: _buildButtons(),
    );
  }

  Widget _buildButtonColumn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: _buildButtons(),
    );
  }

  List<Widget> _buildButtons() {
    return [
      _buildTransferButton('Airport to Accommodation', '/airport_to_accommodation'),
      const SizedBox(height: 8, width: 8),
      _buildTransferButton('Accommodation to Airport', '/airport_to_accommodation'),
      const SizedBox(height: 8, width: 8),
      _buildTransferButton('Other Transfers', '/other_transfer'),
      const SizedBox(height: 8, width: 8),
      _buildTransferButton('Add Car Video', '/other_transfer'),
    ];
  }

  Widget _buildTransferButton(String text, String route) {
    return ElevatedButton(
      onPressed: () {
        Navigator.pop(context);
        Navigator.pushNamed(context, route);
      },
      child: Text(text),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer Search'),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.of(context).pushNamed('/profile');
            },
            icon: const Icon(Icons.account_circle),
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
                ? CustomerFormScreen(onSave: _searchCustomers)
                : _searchResults.isEmpty
                ? const Center(
              child: Text('No customers found. Type to search or click + to add.'),
            )
                : ListView.builder(
              itemCount: _searchResults.length,
              itemBuilder: (context, index) {
                final customer = _searchResults[index];
                return GestureDetector(
                  onLongPress: () => _deleteCustomer(customer.id),
                  child: Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: ListTile(
                      title: Text('${customer.firstName} ${customer.lastName}'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(customer.phone),
                          _buildPhoneActions(customer.phone),
                          if (customer.secondaryPhone != null) ...[
                            const SizedBox(height: 8),
                            Text('Secondary: ${customer.secondaryPhone}'),
                            _buildPhoneActions(customer.secondaryPhone!),
                          ],
                          if (customer.email != null) Text(customer.email!),
                          if (customer.address != null) Text(customer.address!),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: _buildTransferButtons(context),
                          ),
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
