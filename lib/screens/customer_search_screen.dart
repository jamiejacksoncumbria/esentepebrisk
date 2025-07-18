// lib/screens/customer_search_screen.dart

import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photo_view/photo_view.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../models/customer_model.dart';
import '../repositories/customer_repository.dart';
import '../settings/settings_screen.dart';
import 'customer_form_screen.dart';
import '../note_screen/customer_notes_screen.dart';

// Transfers & video & print
import '../transfers_screens/airport_to_accommodation.dart';
import '../transfers_screens/accommodation_to_airport.dart';
import '../transfers_screens/other_transfer.dart';
import '../car_video_screens/car_video_screen.dart';
import '../print_label_screen/print_ticket_screen.dart';

final customerRepositoryProvider = Provider((ref) => CustomerRepository());

class CustomerSearchScreen extends ConsumerStatefulWidget {
  static const routeName = '/customer_form';

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
      final results =
      await ref.read(customerRepositoryProvider).searchCustomers(term);
      setState(() {
        _searchResults = results;
        _showForm = results.isEmpty;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Search failed: $e')));
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteCustomer(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Delete this customer and all their photos?'),
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
        _searchCustomers(_searchController.text.trim());
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('Delete failed: $e')));
        }
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      debugPrint('Could not launch $uri');
    }
  }

  Widget _buildIconButton(
      IconData icon, String tooltip, Color bg, VoidCallback onTap) =>
      CircleAvatar(
        backgroundColor: bg,
        child: IconButton(
          icon: Icon(icon, color: Colors.white, size: 20),
          tooltip: tooltip,
          onPressed: onTap,
        ),
      );

  Widget _buildPhoneActions(String phone) {
    final cleaned = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    return Wrap(
      spacing: 8,
      children: [
        _buildIconButton(
          EvaIcons.messageCircle,
          'WhatsApp Msg',
          Colors.green,
              () => _launchUrl('https://wa.me/$cleaned'),
        ),
        _buildIconButton(
          EvaIcons.phoneCall,
          'WhatsApp Call',
          Colors.green,
              () => _launchUrl('https://wa.me/$cleaned'),
        ),
        if (kIsWeb || Platform.isAndroid || Platform.isIOS)
          _buildIconButton(
            EvaIcons.phone,
            'Call',
            Colors.blue,
                () => _launchUrl('tel:$phone'),
          ),
        if (!kIsWeb && (Platform.isAndroid || Platform.isIOS))
          _buildIconButton(
            EvaIcons.emailOutline,
            'SMS',
            Colors.orange,
                () => _launchUrl('sms:$phone'),
          ),
      ],
    );
  }

  Widget _buildEmailButton(String email) => IconButton(
    icon: const Icon(EvaIcons.email, color: Colors.deepOrange),
    tooltip: 'Email',
    onPressed: () => _launchUrl('mailto:$email'),
  );

  Widget _buildTransferButtons(CustomerModel c) {
    final items = [
      {
        'icons': [Icons.flight, Icons.arrow_circle_right],
        'tooltip': 'Airport → Accommodation',
        'route': AirportToAccommodationScreen.routeName,
      },
      {
        'icons': [Icons.home, Icons.flight],
        'tooltip': 'Accommodation → Airport',
        'route': AccommodationToAirportScreen.routeName,
      },
      {
        'icons': [Icons.local_taxi_outlined, Icons.map_outlined],
        'tooltip': 'Other Transfers',
        'route': '/other_transfer',
      },
      {
        'icons': [EvaIcons.camera, Icons.car_rental],
        'tooltip': 'Add Car Video',
        'route': CarVideoScreen.routeName,
      },
      {
        'icons': [EvaIcons.printerOutline, Icons.description],
        'tooltip': 'Print Hire Label',
        'route': PrintLabelScreen.routeName,
      },
    ];

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        alignment: WrapAlignment.start,
        children: items.map((item) {
          final route = item['route'] as String;
          return Tooltip(
            message: item['tooltip'] as String,
            child: GestureDetector(
              onTap: () {
                if (route == AirportToAccommodationScreen.routeName ||
                    route == AccommodationToAirportScreen.routeName) {
                  Navigator.pushNamed(context, route, arguments: c);
                } else if (route == CarVideoScreen.routeName) {
                  Navigator.pushNamed(context, route, arguments: c.id);
                } else if (route == PrintLabelScreen.routeName) {
                  Navigator.pushNamed(context, route, arguments: c);
                } else {
                  Navigator.pushNamed(context, route);
                }
              },
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.indigo.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: (item['icons'] as List)
                      .map<Widget>((icon) => Padding(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 2),
                    child:
                    Icon(icon as IconData, color: Colors.indigo),
                  ))
                      .toList(),
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
      builder: (_) => Dialog(
        child: PhotoView(
          imageProvider: CachedNetworkImageProvider(url),
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
          child: CachedNetworkImage(
            imageUrl: url,
            width: 80,
            height: 80,
            fit: BoxFit.cover,
            placeholder: (_, __) => const SizedBox(
                width: 80,
                height: 80,
                child:
                Center(child: CircularProgressIndicator())),
            errorWidget: (_, __, ___) => const SizedBox(
                width: 80,
                height: 80,
                child: Icon(Icons.broken_image)),
          ),
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
          IconButton(
            icon: const Icon(EvaIcons.settings),
            onPressed: () =>
                Navigator.of(context).pushNamed(SettingsScreen.routeName),
          ),
          IconButton(
            icon: const Icon(EvaIcons.personOutline),
            onPressed: () => Navigator.of(context).pushNamed('/profile'),
          ),
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
                    : IconButton(
                  icon: const Icon(EvaIcons.search),
                  onPressed: () =>
                      _searchCustomers(_searchController.text.trim()),
                ),
              ),
              onChanged: (v) => _searchCustomers(v.trim()),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _showForm
                ? CustomerFormScreen(
              onSave: () =>
                  _searchCustomers(_searchController.text.trim()),
            )
                : _searchResults.isEmpty
                ? const Center(
              child: Text('No customers found.'),
            )
                : ListView.builder(
              itemCount: _searchResults.length,
              itemBuilder: (_, idx) {
                final c = _searchResults[idx];
                return Card(
                  margin: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  child: ListTile(
                    contentPadding:
                    const EdgeInsets.all(8),
                    title: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        // Photos row
                        if ((c.passportPhotoUrl?.isNotEmpty ??
                            false) ||
                            (c.licensePhotoUrl
                                ?.isNotEmpty ??
                                false))
                          Padding(
                            padding:
                            const EdgeInsets.symmetric(
                                vertical: 8),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment:
                              Alignment.centerLeft,
                              child: Row(
                                crossAxisAlignment:
                                CrossAxisAlignment
                                    .center,
                                children: [
                                  if (c
                                      .passportPhotoUrl
                                      ?.isNotEmpty ??
                                      false) ...[
                                    const Text('Passport',
                                        style: TextStyle(
                                            fontWeight:
                                            FontWeight
                                                .bold)),
                                    const SizedBox(
                                        width: 4),
                                    _buildImagePreview(
                                        c.passportPhotoUrl),
                                    const SizedBox(
                                        width: 12),
                                  ],
                                  if (c
                                      .licensePhotoUrl
                                      ?.isNotEmpty ??
                                      false) ...[
                                    const Text('Licence',
                                        style: TextStyle(
                                            fontWeight:
                                            FontWeight
                                                .bold)),
                                    const SizedBox(
                                        width: 4),
                                    _buildImagePreview(
                                        c.licensePhotoUrl),
                                  ],
                                ],
                              ),
                            ),
                          ),

                        // Passport & License Numbers
                        if (c.passportNumber != null &&
                            c.passportNumber!
                                .isNotEmpty) ...[
                          Text(
                            'Passport No: ${c.passportNumber}',
                            style: const TextStyle(
                                fontWeight:
                                FontWeight.bold,
                                fontSize: 16),
                          ),
                          const SizedBox(height: 4),
                        ],
                        if (c.licenseNumber != null &&
                            c
                                .licenseNumber!
                                .isNotEmpty) ...[
                          Text(
                            'License No: ${c.licenseNumber}',
                            style: const TextStyle(
                                fontWeight:
                                FontWeight.bold,
                                fontSize: 16),
                          ),
                          const SizedBox(height: 8),
                        ],

                        // Name
                        Text(
                            'Firstname: ${c.firstName}',
                            style: const TextStyle(
                                fontWeight:
                                FontWeight.bold,
                                fontSize: 16)),
                        Text(
                            'Surname: ${c.lastName}',
                            style: const TextStyle(
                                fontWeight:
                                FontWeight.bold,
                                fontSize: 16)),

                        // Address
                        if (c.address != null &&
                            c.address!.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text('Address: ${c.address}',
                              style: const TextStyle(
                                  fontWeight:
                                  FontWeight.bold,
                                  fontSize: 16)),
                        ],

                        // Lat / Lng
                        if (c.location != null) ...[
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Lat: ${c.location!.latitude.toStringAsFixed(6)}, '
                                      'Lng: ${c.location!.longitude.toStringAsFixed(6)}',
                                  style: const TextStyle(
                                      fontSize: 14),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                    EvaIcons
                                        .navigation2),
                                tooltip:
                                'Open in Google Maps',
                                onPressed: () => _launchUrl(
                                    'https://www.google.com/maps/search/?api=1&query=${c.location!.latitude},${c.location!.longitude}'),
                              ),
                            ],
                          ),
                        ],

                        const SizedBox(height: 6),
                        // Phone & actions
                        Text(c.phone,
                            style: const TextStyle(
                                fontWeight:
                                FontWeight.bold,
                                fontSize: 16)),
                        const SizedBox(height: 6),
                        _buildPhoneActions(c.phone),
                        if (c.secondaryPhone != null) ...[
                          const SizedBox(height: 6),
                          Text(
                              'Secondary: ${c.secondaryPhone}',
                              style: const TextStyle(
                                  fontWeight:
                                  FontWeight.bold,
                                  fontSize: 16)),
                          const SizedBox(height: 6),
                          _buildPhoneActions(
                              c.secondaryPhone!),
                        ],

                        // Email
                        if (c.email != null) ...[
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              _buildEmailButton(
                                  c.email!),
                              Text(c.email!,
                                  style: const TextStyle(
                                      fontWeight:
                                      FontWeight.bold,
                                      fontSize:
                                      16)),
                            ],
                          ),
                        ],

                        // Transfers
                        _buildTransferButtons(c),

                        if (c.latestNoteSnippet != null) ...[
                          const SizedBox(height: 8),
                          Text(
                              'Note: ${c.latestNoteSnippet}',
                              style: const TextStyle(
                                  fontStyle:
                                  FontStyle.italic)),
                        ],

                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          icon: const Icon(
                              EvaIcons.editOutline),
                          label:
                          const Text('View/Add Notes'),
                          onPressed: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    CustomerNotesScreen(
                                      customerId: c.id,
                                      onUpdate: () =>
                                          _searchCustomers(
                                              _lastSearchTerm ??
                                                  ''),
                                    ),
                              ),
                            );
                            _searchCustomers(
                                _lastSearchTerm ?? '');
                          },
                        ),
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(EvaIcons.edit),
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              CustomerFormScreen(
                                customer: c,
                                onSave: () =>
                                    _searchCustomers(
                                        _searchController
                                            .text
                                            .trim()),
                              ),
                        ),
                      ),
                    ),
                    onLongPress: () =>
                        _deleteCustomer(c.id),
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
