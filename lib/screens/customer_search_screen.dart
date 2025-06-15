import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photo_view/photo_view.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:eva_icons_flutter/eva_icons_flutter.dart';

import '../models/customer_model.dart';
import '../repositories/customer_repository.dart';
import 'customer_form_screen.dart';
import '../note_screen/customer_notes_screen.dart';

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
  String? _lastSearchTerm;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.searchTerm);
    if (widget.searchTerm != null && widget.searchTerm!.isNotEmpty) {
      _searchCustomers(widget.searchTerm!);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchCustomers(String term) async {
    setState(() {
      _isLoading = true;
      _lastSearchTerm = term;
    });
    try {
      final results = await ref
          .read(customerRepositoryProvider)
          .searchCustomers(term);
      setState(() {
        _searchResults = results;
        _showForm = results.isEmpty;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Search failed: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteCustomer(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) =>
          AlertDialog(
            title: const Text('Confirm Delete'),
            content: const Text('Delete this customer and all their photos?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel')),
              TextButton(onPressed: () => Navigator.pop(context, true),
                  child: const Text(
                      'Delete', style: TextStyle(color: Colors.red))),
            ],
          ),
    );
    if (confirmed == true) {
      setState(() => _isLoading = true);
      try {
        await ref.read(customerRepositoryProvider).deleteCustomer(id);
        _searchCustomers(_searchController.text.trim());
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Delete failed: $e')),
          );
        }
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Widget _buildIconButton(IconData icon, String tooltip, Color bg,
      VoidCallback onTap) {
    return CircleAvatar(
      backgroundColor: bg,
      child: IconButton(icon: Icon(icon, color: Colors.white, size: 20),
          tooltip: tooltip,
          onPressed: onTap),
    );
  }

  Widget _buildPhoneActions(String phone) {
    final cleaned = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    return Wrap(
      spacing: 8,
      children: [
        _buildIconButton(
            EvaIcons.messageCircle, 'WhatsApp Msg', Colors.green, () =>
            _launchUrl('https://wa.me/$cleaned')),
        _buildIconButton(
            EvaIcons.phoneCall, 'WhatsApp Call', Colors.green, () =>
            _launchUrl('https://wa.me/$cleaned')),
        if (kIsWeb || Platform.isAndroid || Platform.isIOS)
          _buildIconButton(EvaIcons.phone, 'Call', Colors.blue, () =>
              _launchUrl('tel:$phone')),
        if (Platform.isAndroid || Platform.isIOS)
          _buildIconButton(EvaIcons.emailOutline, 'SMS', Colors.orange, () =>
              _launchUrl('sms:$phone')),
      ],
    );
  }

  Widget _buildEmailButton(String email) {
    return IconButton(
        icon: const Icon(EvaIcons.email, color: Colors.deepOrange),
        tooltip: 'Email',
        onPressed: () => _launchUrl('mailto:$email'));
  }

  Widget _buildTransferButtons() {
    final items = [
      {
        'icons': [Icons.flight, Icons.arrow_circle_right],
        'tooltip': 'Airport → Accommodation',
        'route': '/airport_to_accommodation'
      },
      {
        'icons': [Icons.home, Icons.flight],
        'tooltip': 'Accommodation → Airport',
        'route': '/airport_to_accommodation'
      },
      {
        'icons': [Icons.local_taxi_outlined, Icons.map_outlined],
        'tooltip': 'Other Transfers',
        'route': '/other_transfer'
      },
      {
        'icons': [EvaIcons.camera, Icons.car_rental],
        'tooltip': 'Add Car Video',
        'route': '/car_video'
      },
      {
        'icons': [EvaIcons.printerOutline, Icons.description],
        'tooltip': 'Print Hire Label',
        'route': '/print_label'
      },
    ];

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        alignment: WrapAlignment.start,
        children: items.map((item) {
          return Tooltip(
            message: item['tooltip']! as String,
            child: GestureDetector(
              onTap: () =>
                  Navigator.pushNamed(context, item['route']! as String),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.indigo.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: (item['icons']! as List).map<Widget>((icon) =>
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: Icon(icon as IconData, color: Colors.indigo),
                      )).toList(),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  void _showPhotoPreview(String? url) {
    if (url == null) return;
    showDialog(
      context: context,
      builder: (_) =>
          Dialog(
            child: PhotoView(
              imageProvider: NetworkImage(url) as ImageProvider,
              minScale: PhotoViewComputedScale.contained,
              maxScale: PhotoViewComputedScale.covered * 2,
            ),
          ),
    );
  }

  Widget _buildImagePreview(String? url) {
    if (url == null) return const SizedBox();
    return GestureDetector(
      onTap: () => _showPhotoPreview(url),
      child: Padding(
        padding: const EdgeInsets.only(right: 8.0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Image.network(url, width: 80, height: 80, fit: BoxFit.cover),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer Search'),
        actions: [
          IconButton(icon: const Icon(EvaIcons.settings),
              onPressed: () =>
                  Navigator.of(context).pushNamed('/settings_screen')),
          IconButton(icon: const Icon(EvaIcons.personOutline),
              onPressed: () => Navigator.of(context).pushNamed('/profile')),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search by name, phone, or email',
                suffixIcon: _isLoading
                    ? null
                    : IconButton(icon: const Icon(EvaIcons.search),
                    onPressed: () =>
                        _searchCustomers(_searchController.text.trim())),
              ),
              onChanged: (v) => _searchCustomers(v.trim()),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _showForm
                ? CustomerFormScreen(
                onSave: () => _searchCustomers(_searchController.text.trim()))
                : _searchResults.isEmpty
                ? const Center(child: Text('No customers found.'))
                : ListView.builder(
              itemCount: _searchResults.length,
              itemBuilder: (_, idx) {
                final c = _searchResults[idx];
                return Card(
                  margin: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(8),
                    title: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if ((c.passportPhotoUrl?.isNotEmpty ?? false) ||
                            (c.licensePhotoUrl?.isNotEmpty ?? false))
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  if (c.passportPhotoUrl?.isNotEmpty ?? false) ...[
                                    const Text(
                                      'Passport',
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(width: 4),
                                    _buildImagePreview(c.passportPhotoUrl),
                                    const SizedBox(width: 12),
                                  ],
                                  if (c.licensePhotoUrl?.isNotEmpty ?? false) ...[
                                    const Text(
                                      'Licence',
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(width: 4),
                                    _buildImagePreview(c.licensePhotoUrl),
                                  ],
                                ],
                              ),
                            ),
                          )
                        else
                          const SizedBox.shrink(),
                        const SizedBox(height: 8),
                        // Name + address
                        Text('Firstname: ${c.firstName}',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                        Text('Surname: ${c.lastName}', style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                        if (c.address != null && c.address!.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text('Address: ${c.address}', style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                        ],
                        const SizedBox(height: 6),
                        // Phone
                        Text(c.phone, style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 6),
                        _buildPhoneActions(c.phone),
                        if (c.secondaryPhone != null) ...[
                          const SizedBox(height: 6),
                          Text('Secondary: ${c.secondaryPhone}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 6),
                          _buildPhoneActions(c.secondaryPhone!),
                        ],
                        if (c.email != null) ...[
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              _buildEmailButton(c.email!),
                              Text(c.email!, style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16)),
                            ],
                          ),
                        ],
                        // Transfers
                        _buildTransferButtons(),
                        if (c.latestNoteSnippet != null) ...[
                          const SizedBox(height: 8),
                          Text('Note: ${c.latestNoteSnippet}',
                              style: const TextStyle(
                                  fontStyle: FontStyle.italic)),
                        ],
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          icon: const Icon(EvaIcons.editOutline),
                          label: const Text('View/Add Notes'),
                          onPressed: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    CustomerNotesScreen(
                                      customerId: c.id,
                                      onUpdate: () =>
                                          _searchCustomers(
                                              _lastSearchTerm ?? ''),
                                    ),
                              ),
                            );
                            _searchCustomers(_lastSearchTerm ?? '');
                          },
                        ),
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(EvaIcons.edit),
                      onPressed: () =>
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  CustomerFormScreen(
                                    customer: c,
                                    onSave: () =>
                                        _searchCustomers(
                                            _searchController.text.trim()),
                                  ),
                            ),
                          ),
                    ),
                    onLongPress: () => _deleteCustomer(c.id),
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
