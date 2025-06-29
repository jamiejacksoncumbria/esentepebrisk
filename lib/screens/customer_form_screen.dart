// lib/screens/customer_form_screen.dart

import 'dart:async';
import 'dart:io' show File, Platform;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_maps_url_extractor/google_maps_url_extractor.dart';
import 'package:geolocator/geolocator.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:photo_view/photo_view.dart';
import 'package:recase/recase.dart';
import 'package:uuid/uuid.dart';
import 'package:image_compression/image_compression.dart'; // ^1.0.5
import 'package:url_launcher/url_launcher.dart';

import '../models/customer_model.dart';
import 'customer_search_screen.dart';

/// A form for creating or editing a customer.
///
/// - Guards against unsaved changes with PopScope.
/// - Compresses images with image_compression on all platforms.
/// - Extracts lat/lng from Google Maps URLs.
/// - Title-cases names & address, normalizes phones with '+'.
/// - Only shows "Get Current Location" on mobile.
class CustomerFormScreen extends ConsumerStatefulWidget {
  final CustomerModel? customer;
  final VoidCallback? onSave;

  const CustomerFormScreen({super.key, this.customer, this.onSave});

  @override
  ConsumerState<CustomerFormScreen> createState() => _CustomerFormScreenState();
}

class _CustomerFormScreenState extends ConsumerState<CustomerFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _phone2Controller = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _latController = TextEditingController();
  final _lngController = TextEditingController();
  final _urlController = TextEditingController();
  final _passportNumberController = TextEditingController();
  final _licenseNumberController = TextEditingController();

  XFile? _passportPhoto;
  XFile? _licensePhoto;
  Position? _currentPosition;
  bool _isLoading = false;
  bool _passportPhotoUpdated = false;
  bool _licensePhotoUpdated = false;
  bool _hasUnsavedChanges = false;

  @override
  void initState() {
    super.initState();
    if (widget.customer != null) _initializeForm(widget.customer!);
    for (var c in [
      _firstNameController,
      _lastNameController,
      _phoneController,
      _phone2Controller,
      _emailController,
      _addressController,
      _latController,
      _lngController,
      _urlController,
      _passportNumberController,
      _licenseNumberController,
    ]) {
      c.addListener(_markDirty);
    }
  }

  void _initializeForm(CustomerModel c) {
    _firstNameController.text = c.firstName;
    _lastNameController.text = c.lastName;
    _phoneController.text = c.phone;
    _phone2Controller.text = c.secondaryPhone ?? '';
    _emailController.text = c.email ?? '';
    _addressController.text = c.address ?? '';
    _passportNumberController.text = c.passportNumber ?? '';
    _licenseNumberController.text = c.licenseNumber ?? '';

    if (c.location != null) {
      _latController.text = c.location!.latitude.toStringAsFixed(6);
      _lngController.text = c.location!.longitude.toStringAsFixed(6);
      _currentPosition = Position(
        latitude: c.location!.latitude,
        longitude: c.location!.longitude,
        timestamp: DateTime.now(),
        accuracy: 0,
        altitude: 0,
        heading: 0,
        speed: 0,
        altitudeAccuracy: 0,
        headingAccuracy: 0,
        speedAccuracy: 0,
      );
    }
  }

  void _markDirty() {
    if (!_hasUnsavedChanges) setState(() => _hasUnsavedChanges = true);
  }

  Future<void> _convertUrl() async {
    final text = _urlController.text.trim();
    debugPrint('▶️ _convertUrl() called with: $text');

    if (text.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a Google Maps URL')),
        );
      }
      return;
    }

    Map<String, double>? coords;

    try {
      // 1) Built-in extractor
      debugPrint('…trying GoogleMapsUrlExtractor.processGoogleMapsUrl');
      coords = await GoogleMapsUrlExtractor.processGoogleMapsUrl(text);
      debugPrint('…built-in extractor returned: $coords');

      // 2) Fallback for share links
      if (coords == null &&
          (text.contains('goo.gl') || text.contains('maps.app.goo.gl'))) {
        debugPrint('…built-in failed, attempting HTTP HEAD to catch redirects');
        final client = http.Client();

        final headReq = http.Request('HEAD', Uri.parse(text))
          ..headers['User-Agent'] = 'Mozilla/5.0'
          ..followRedirects = false;
        final headRes = await client.send(headReq);
        debugPrint('…HEAD status: ${headRes.statusCode}');
        final loc = headRes.headers['location'];
        debugPrint('…HEAD redirect location: $loc');

        if (loc != null) {
          // 2a) Try package extractor
          coords = GoogleMapsUrlExtractor.extractCoordinates(loc);
          debugPrint('…coords from HEAD redirect via extractor: $coords');

          // 2b) Manual regex fallback
          if (coords == null) {
            final m = RegExp(
              r'/search/(-?\d+\.\d+),\+?(-?\d+\.\d+)',
            ).firstMatch(loc);
            if (m != null) {
              final lat = double.tryParse(m.group(1)!);
              final lng = double.tryParse(m.group(2)!);
              if (lat != null && lng != null) {
                coords = {'latitude': lat, 'longitude': lng};
                debugPrint('…manual /search regex coords: $coords');
              } else {
                debugPrint('…regex parsed but parseDouble failed');
              }
            } else {
              debugPrint('…manual regex did not match');
            }
          }
        }

        client.close();
      }

      // 3) Apply coords, show success, or show error
      if (coords != null) {
        final lat = coords['latitude']!;
        final lng = coords['longitude']!;
        debugPrint('✅ extracted coords: $lat, $lng');

        if (mounted) {
          setState(() {
            _latController.text = lat.toStringAsFixed(6);
            _lngController.text = lng.toStringAsFixed(6);
            _currentPosition = Position(
              latitude: lat,
              longitude: lng,
              timestamp: DateTime.now(),
              accuracy: 0,
              altitude: 0,
              heading: 0,
              speed: 0,
              altitudeAccuracy: 0,
              headingAccuracy: 0,
              speedAccuracy: 0,
            );
          });
          _markDirty();

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Coordinates extracted successfully! Don’t forget to save the customer.',
              ),
            ),
          );
        }
      } else {
        debugPrint('❌ unable to extract coordinates after all attempts');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Unable to extract coordinates')),
          );
        }
      }
    } catch (e, st) {
      debugPrint('⚠️ error in _convertUrl(): $e\n$st');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    }
  }

  Future<bool> _showDiscardDialog() async {
    final discard = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Unsaved Changes'),
        content: const Text('You have unsaved changes. Discard them?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    return discard == true;
  }

  @override
  void dispose() {
    for (var c in [
      _firstNameController,
      _lastNameController,
      _phoneController,
      _phone2Controller,
      _emailController,
      _addressController,
      _latController,
      _lngController,
      _urlController,
      _passportNumberController,
      _licenseNumberController,
    ]) {
      c.removeListener(_markDirty);
      c.dispose();
    }
    super.dispose();
  }

  Future<XFile?> compressImage(XFile file) async {
    final bytes = await file.readAsBytes();
    if (!mounted) return null;
    final inFile = ImageFile(rawBytes: bytes, filePath: file.path);
    final outFile = await compressInQueue(
      ImageFileConfiguration(input: inFile),
    );
    if (!mounted) return null;

    final ext = outFile.extension.isNotEmpty ? outFile.extension : 'jpg';
    final name = outFile.fileName.isNotEmpty ? outFile.fileName : Uuid().v4();
    _markDirty();

    if (kIsWeb) {
      return XFile.fromData(outFile.rawBytes, name: '$name.$ext');
    }
    final dir = await getTemporaryDirectory();
    final path = '${dir.path}/$name.$ext';
    await File(path).writeAsBytes(outFile.rawBytes);
    return XFile(path);
  }

  Future<void> _pickImage(bool isPassport) async {
    final picker = ImagePicker();

    Future<void> handle(ImageSource src) async {
      if (!kIsWeb) {
        Permission? perm;
        if (src == ImageSource.camera) {
          perm = Permission.camera;
        } else if (Platform.isIOS) {
          perm = Permission.photos;
        }
        if (perm != null) {
          final status = await perm.request();
          if (!status.isGranted && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${perm.toString().split('.').last} denied'),
              ),
            );
            return;
          }
        }
      }

      final picked = await picker.pickImage(source: src);
      if (picked != null) {
        final comp = await compressImage(picked);
        if (!mounted || comp == null) return;
        setState(() {
          if (isPassport) {
            _passportPhoto = comp;
            _passportPhotoUpdated = true;
          } else {
            _licensePhoto = comp;
            _licensePhotoUpdated = true;
          }
        });
      }
    }

    // Desktop: gallery only
    if (!kIsWeb &&
        (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      await handle(ImageSource.gallery);
      return;
    }

    final hasCam = await Permission.camera.request().isGranted;
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Select from Gallery'),
              onTap: () {
                Navigator.pop(context);
                handle(ImageSource.gallery);
              },
            ),
            if (hasCam)
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Take Photo'),
                onTap: () {
                  Navigator.pop(context);
                  handle(ImageSource.camera);
                },
              ),
          ],
        ),
      ),
    );
  }

  void _showPhotoPreview(String? url, XFile? file) {
    if (!mounted) return;
    if (url == null && file == null) return;
    final provider = file != null
        ? FileImage(File(file.path))
        : NetworkImage(url!) as ImageProvider;
    showDialog(
      context: context,
      builder: (_) => Dialog(
        child: PhotoView(
          imageProvider: provider,
          minScale: PhotoViewComputedScale.contained,
          maxScale: PhotoViewComputedScale.covered * 2,
        ),
      ),
    );
  }

  Future<void> _getCurrentLocation() async {
    if (kIsWeb || !(Platform.isAndroid || Platform.isIOS)) return;
    setState(() => _isLoading = true);
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location services disabled')),
          );
        }
        return;
      }
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
        if (perm == LocationPermission.denied && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permission denied')),
          );
          return;
        }
      }
      if (perm == LocationPermission.deniedForever && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permanently denied')),
        );
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      if (!mounted) return;
      setState(() {
        _currentPosition = pos;
        _latController.text = pos.latitude.toStringAsFixed(6);
        _lngController.text = pos.longitude.toStringAsFixed(6);
      });
      _markDirty();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error getting location: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _updateLocationFromText() {
    final lat = double.tryParse(_latController.text);
    final lng = double.tryParse(_lngController.text);
    if (lat != null && lng != null && mounted) {
      setState(() {
        _currentPosition = Position(
          latitude: lat,
          longitude: lng,
          timestamp: DateTime.now(),
          accuracy: 0,
          altitude: 0,
          heading: 0,
          speed: 0,
          altitudeAccuracy: 0,
          headingAccuracy: 0,
          speedAccuracy: 0,
        );
      });
      _markDirty();
    }
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not launch $url')));
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    String normalize(String input) {
      final d = input.replaceAll('+', '').trim();
      return d.isEmpty ? '' : '+$d';
    }

    String toTitle(String s) => ReCase(s).titleCase;

    try {
      final repo = ref.read(customerRepositoryProvider);
      var cust =
          widget.customer ??
          CustomerModel(
            id: '',
            firstName: '',
            lastName: '',
            phone: '',
            secondaryPhone: null,
            email: null,
            address: null,
            location: null,
            passportPhotoUrl: null,
            licensePhotoUrl: null,
            searchTerms: [],
            createdAt: Timestamp.now(),
          );

      cust = cust.copyWith(
        firstName: toTitle(_firstNameController.text.trim()),
        lastName: toTitle(_lastNameController.text.trim()),
        phone: normalize(_phoneController.text),
        secondaryPhone: _phone2Controller.text.isEmpty
            ? null
            : normalize(_phone2Controller.text),
        email: _emailController.text.isEmpty
            ? null
            : _emailController.text.trim(),
        address: _addressController.text.isEmpty
            ? null
            : toTitle(_addressController.text.trim()),
        location: _currentPosition == null
            ? null
            : GeoPoint(_currentPosition!.latitude, _currentPosition!.longitude),
        searchTerms: _generateSearchTerms(),
        passportNumber: _passportNumberController.text.isEmpty
            ? null
            : _passportNumberController.text.trim(),
        licenseNumber: _licenseNumberController.text.isEmpty
            ? null
            : _licenseNumberController.text.trim(),
      );

      if (_passportPhotoUpdated && _passportPhoto != null) {
        cust = cust.copyWith(
          passportPhotoUrl: await repo.uploadPhoto(
            customerId: cust.id,
            file: _passportPhoto!,
            type: 'passport',
          ),
        );
      }
      if (_licensePhotoUpdated && _licensePhoto != null) {
        cust = cust.copyWith(
          licensePhotoUrl: await repo.uploadPhoto(
            customerId: cust.id,
            file: _licensePhoto!,
            type: 'license',
          ),
        );
      }

      if (widget.customer == null) {
        await repo.createCustomer(cust);
      } else {
        await repo.updateCustomer(cust);
      }

      _hasUnsavedChanges = false;
      widget.onSave?.call();
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => CustomerSearchScreen(
            searchTerm: '${cust.firstName} ${cust.lastName}',
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<String> _generateSearchTerms() {
    final terms = <String>{};
    void add(String s) {
      final t = s.trim();
      if (t.length >= 3) {
        for (var i = 3; i <= t.length; i++) {
          terms.add(t.substring(0, i).toLowerCase());
        }
      }
    }

    add(_firstNameController.text);
    add('${_firstNameController.text}${_lastNameController.text}');
    add('${_firstNameController.text} ${_lastNameController.text}');
    add(_lastNameController.text);
    final p1 = _phoneController.text.replaceAll('+', '');
    add(p1);
    add('+$p1');
    if (_phone2Controller.text.isNotEmpty) {
      final p2 = _phone2Controller.text.replaceAll('+', '');
      add(p2);
      add('+$p2');
    }
    if (_emailController.text.isNotEmpty) add(_emailController.text);
    if (_addressController.text.isNotEmpty) {
      for (var w in _addressController.text.split(' ')) {
        add(w);
      }
    }
    return terms.toList();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope<bool>(
      canPop: !_hasUnsavedChanges,
      onPopInvokedWithResult: (didPop, _) async {
        if (!didPop && _hasUnsavedChanges) {
          final discard = await _showDiscardDialog();
          if (discard && mounted) {
            setState(() => _hasUnsavedChanges = false);
            if (context.mounted) Navigator.of(context).pop();
          }
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.customer == null ? 'New Customer' : 'Edit Customer',
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // First Name
                      TextFormField(
                        controller: _firstNameController,
                        decoration: const InputDecoration(
                          labelText: 'First Name*',
                        ),
                        validator: (v) => v!.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 8),
                      // Last Name
                      TextFormField(
                        controller: _lastNameController,
                        decoration: const InputDecoration(
                          labelText: 'Last Name*',
                        ),
                        validator: (v) => v!.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 8),
                      // Phone
                      TextFormField(
                        controller: _phoneController,
                        decoration: const InputDecoration(
                          labelText: 'Phone*',
                          prefixText: '+',
                        ),
                        keyboardType: TextInputType.phone,
                        validator: (v) => v!.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 8),
                      // Secondary Phone
                      TextFormField(
                        controller: _phone2Controller,
                        decoration: const InputDecoration(
                          labelText: 'Secondary Phone',
                          prefixText: '+',
                        ),
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 8),
                      // Email
                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(labelText: 'Email'),
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 8),
                      // Address
                      TextFormField(
                        controller: _addressController,
                        decoration: const InputDecoration(labelText: 'Address'),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 16),
                      // Lat/Lng + buttons
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _latController,
                              decoration: const InputDecoration(
                                labelText: 'Latitude',
                                prefixIcon: Icon(Icons.location_on),
                              ),
                              keyboardType: TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                              onChanged: (_) => _updateLocationFromText(),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _lngController,
                              decoration: const InputDecoration(
                                labelText: 'Longitude',
                                prefixIcon: Icon(Icons.location_on),
                              ),
                              keyboardType: TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                              onChanged: (_) => _updateLocationFromText(),
                            ),
                          ),
                          if (!kIsWeb && (Platform.isAndroid || Platform.isIOS))
                            IconButton(
                              icon: const Icon(Icons.my_location),
                              tooltip: 'Get Current Location',
                              onPressed: _getCurrentLocation,
                            ),
                          if (_latController.text.isNotEmpty &&
                              _lngController.text.isNotEmpty)
                            IconButton(
                              icon: const Icon(Icons.navigation),
                              tooltip: 'Open in Google Maps',
                              onPressed: () {
                                final lat = _latController.text;
                                final lng = _lngController.text;
                                _launchUrl(
                                  'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
                                );
                              },
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Google Maps URL extractor
                      TextFormField(
                        controller: _urlController,
                        decoration: const InputDecoration(
                          labelText: 'Google Maps URL',
                          hintText: 'Paste short or long URL here',
                        ),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: _convertUrl,
                        child: const Text('Convert URL → Lat/Lng'),
                      ),
                      const SizedBox(height: 24),
                      // Identification Photos
                      const Text(
                        'Identification Photos',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // ← NEW: Identification Numbers
                      const Text(
                        'Identification Numbers',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),

                      TextFormField(
                        controller: _passportNumberController,
                        decoration: const InputDecoration(
                          labelText: 'Passport Number',
                        ),
                      ),
                      const SizedBox(height: 8),

                      TextFormField(
                        controller: _licenseNumberController,
                        decoration: const InputDecoration(
                          labelText: 'Driving License Number',
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Column(
                            children: [
                              const Text('Passport Photo'),
                              const SizedBox(height: 8),
                              GestureDetector(
                                onTap: () => _pickImage(true),
                                onLongPress: () => _showPhotoPreview(
                                  widget.customer?.passportPhotoUrl,
                                  _passportPhoto,
                                ),
                                child: Container(
                                  height: 120,
                                  width: 120,
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: _passportPhoto != null
                                  // local file still uses Image.file
                                      ? Image.file(
                                    File(_passportPhoto!.path),
                                    fit: BoxFit.cover,
                                  )
                                  // else load & cache from network
                                      : (widget.customer?.passportPhotoUrl != null
                                      ? ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: CachedNetworkImage(
                                      imageUrl: widget.customer!.passportPhotoUrl!,
                                      fit: BoxFit.cover,
                                      width: 120,
                                      height: 120,
                                      placeholder: (_, _) => const SizedBox(
                                        width: 120,
                                        height: 120,
                                        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                                      ),
                                      errorWidget: (_, _, _) => const Icon(Icons.broken_image, size: 40),
                                    ),
                                  )
                                      : const Icon(
                                    Icons.add_a_photo,
                                    size: 40,
                                  )),
                                ),
                              ),

                            ],
                          ),
                          Column(
                            children: [
                              const Text('Driving License'),
                              const SizedBox(height: 8),
                              GestureDetector(
                                onTap: () => _pickImage(false),
                                onLongPress: () => _showPhotoPreview(
                                  widget.customer?.licensePhotoUrl,
                                  _licensePhoto,
                                ),
                                child: Container(
                                  height: 120,
                                  width: 120,
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: _licensePhoto != null
                                  // Local file
                                      ? Image.file(
                                    File(_licensePhoto!.path),
                                    fit: BoxFit.cover,
                                  )
                                  // Cached network image
                                      : (widget.customer?.licensePhotoUrl != null
                                      ? ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: CachedNetworkImage(
                                      imageUrl: widget.customer!.licensePhotoUrl!,
                                      fit: BoxFit.cover,
                                      width: 120,
                                      height: 120,
                                      placeholder: (_, _) => const SizedBox(
                                        width: 120,
                                        height: 120,
                                        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                                      ),
                                      errorWidget: (_, _, _) => const Icon(Icons.broken_image, size: 40),
                                    ),
                                  )
                                      : const Icon(
                                    Icons.add_a_photo,
                                    size: 40,
                                  )),
                                ),
                              ),

                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _submitForm,
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(50),
                        ),
                        child: const Text('Save Customer'),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
