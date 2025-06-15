// lib/screens/customer_form_screen.dart

import 'dart:io' show File, Platform;
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
import 'package:image_compression/image_compression.dart'; // image_compression: ^1.0.5

import '../models/customer_model.dart';
import 'customer_search_screen.dart';

class CustomerFormScreen extends ConsumerStatefulWidget {
  final CustomerModel? customer;
  final VoidCallback? onSave;

  const CustomerFormScreen({
    super.key,
    this.customer,
    this.onSave,
  });

  @override
  ConsumerState<CustomerFormScreen> createState() => _CustomerFormScreenState();
}

class _CustomerFormScreenState extends ConsumerState<CustomerFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController  = TextEditingController();
  final _phoneController     = TextEditingController();
  final _phone2Controller    = TextEditingController();
  final _emailController     = TextEditingController();
  final _addressController   = TextEditingController();
  final _latController       = TextEditingController();
  final _lngController       = TextEditingController();
  final _urlController       = TextEditingController();

  XFile?    _passportPhoto;
  XFile?    _licensePhoto;
  Position? _currentPosition;
  bool      _isLoading            = false;
  bool      _passportPhotoUpdated = false;
  bool      _licensePhotoUpdated  = false;

  @override
  void initState() {
    super.initState();
    if (widget.customer != null) {
      _initializeForm(widget.customer!);
    }
  }

  void _initializeForm(CustomerModel customer) {
    _firstNameController.text = customer.firstName;
    _lastNameController.text  = customer.lastName;
    _phoneController.text     = customer.phone;
    _phone2Controller.text    = customer.secondaryPhone ?? '';
    _emailController.text     = customer.email ?? '';
    _addressController.text   = customer.address ?? '';
    if (customer.location != null) {
      _latController.text = customer.location!.latitude.toStringAsFixed(6);
      _lngController.text = customer.location!.longitude.toStringAsFixed(6);
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _phone2Controller.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _latController.dispose();
    _lngController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  /// Compresses images using image_compression on all platforms.
  Future<XFile?> compressImage(XFile file) async {
    final bytes = await file.readAsBytes();
    final input = ImageFile(rawBytes: bytes, filePath: file.path);
    final output = await compressInQueue(
      ImageFileConfiguration(input: input),
    );
    final ext  = output.extension.isNotEmpty ? output.extension : 'jpg';
    final name = output.fileName .isNotEmpty ? output.fileName   : Uuid().v4();

    if (kIsWeb) {
      return XFile.fromData(output.rawBytes, name: '$name.$ext');
    }
    final dir  = await getTemporaryDirectory();
    final path = '${dir.path}/$name.$ext';
    await File(path).writeAsBytes(output.rawBytes);
    return XFile(path);
  }

  Future<void> _pickImage(bool isPassport) async {
    final picker = ImagePicker();

    Future<void> handlePick(ImageSource src) async {
      if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
        final perm = src == ImageSource.camera
            ? Permission.camera
            : (Platform.isIOS ? Permission.photos : Permission.storage);
        if (!await perm.request().isGranted && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${perm.toString().split('.').last} denied')),
          );
          return;
        }
      }
      final picked = await picker.pickImage(source: src);
      if (picked != null) {
        final compressed = await compressImage(picked);
        if (!mounted) return;
        if (compressed != null) {
          setState(() {
            if (isPassport) {
              _passportPhoto        = compressed;
              _passportPhotoUpdated = true;
            } else {
              _licensePhoto        = compressed;
              _licensePhotoUpdated = true;
            }
          });
        }
      }
    }

    if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      await handlePick(ImageSource.gallery);
      return;
    }
    final hasCam = await Permission.camera.request().isGranted;
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(
            leading: const Icon(Icons.photo_library),
            title: const Text('Select from Gallery'),
            onTap: () {
              Navigator.pop(context);
              handlePick(ImageSource.gallery);
            },
          ),
          if (hasCam)
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(context);
                handlePick(ImageSource.camera);
              },
            ),
        ]),
      ),
    );
  }

  void _showPhotoPreview(String? url, XFile? file) {
    if (url == null && file == null) return;
    final provider = file != null
        ? FileImage(File(file.path))
        : NetworkImage(url!) as ImageProvider;
    if (!mounted) return;
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
    if (mounted) setState(() => _isLoading = true);
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
      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      if (!mounted) return;
      setState(() {
        _currentPosition    = pos;
        _latController.text = pos.latitude.toStringAsFixed(6);
        _lngController.text = pos.longitude.toStringAsFixed(6);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error getting location: $e')),
      );
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
          latitude: lat, longitude: lng,
          timestamp: DateTime.now(),
          accuracy: 0, altitude: 0,
          heading: 0, speed: 0,
          altitudeAccuracy: 0,
          headingAccuracy: 0,
          speedAccuracy: 0,
        );
      });
    }
  }

  Future<void> _convertUrl() async {
    final url = _urlController.text.trim();
    if (url.isEmpty && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a Google Maps URL')),
      );
      return;
    }
    try {
      final coords = await GoogleMapsUrlExtractor.processGoogleMapsUrl(url);
      if (coords != null && mounted) {
        setState(() {
          _latController.text = coords['latitude']!.toStringAsFixed(6);
          _lngController.text = coords['longitude']!.toStringAsFixed(6);
          _currentPosition = Position(
            latitude: coords['latitude']!,
            longitude: coords['longitude']!,
            timestamp: DateTime.now(),
            accuracy: 0, altitude: 0,
            heading: 0, speed: 0,
            altitudeAccuracy: 0,
            headingAccuracy: 0,
            speedAccuracy: 0,
          );
        });
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to extract coordinates')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error extracting coordinates: $e')),
      );
      }
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    if (mounted) setState(() => _isLoading = true);

    String normalize(String input) {
      final digits = input.replaceAll('+', '').trim();
      return digits.isEmpty ? '' : '+$digits';
    }
    String toTitle(String s) => ReCase(s).titleCase;

    try {
      final repo = ref.read(customerRepositoryProvider);
      var cust = widget.customer ?? CustomerModel(
        id: '', firstName: '', lastName: '', phone: '',
        secondaryPhone: null, email: null, address: null,
        location: null, passportPhotoUrl: null, licensePhotoUrl: null,
        searchTerms: [], createdAt: Timestamp.now(),
      );

      cust = cust.copyWith(
        firstName:      toTitle(_firstNameController.text.trim()),
        lastName:       toTitle(_lastNameController.text.trim()),
        phone:          normalize(_phoneController.text),
        secondaryPhone: _phone2Controller.text.isEmpty
            ? null
            : normalize(_phone2Controller.text),
        email:          _emailController.text.isEmpty
            ? null
            : _emailController.text.trim(),
        address:        _addressController.text.isEmpty
            ? null
            : toTitle(_addressController.text.trim()),
        location:       _currentPosition == null
            ? null
            : GeoPoint(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
        ),
        searchTerms:    _generateSearchTerms(),
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

      widget.onSave?.call();
      if (mounted) {
        Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => CustomerSearchScreen(
            searchTerm: '${cust.firstName} ${cust.lastName}',
          ),
        ),
      );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
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
    add(p1); add('+$p1');
    if (_phone2Controller.text.isNotEmpty) {
      final p2 = _phone2Controller.text.replaceAll('+', '');
      add(p2); add('+$p2');
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
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.customer == null ? 'New Customer' : 'Edit Customer'),
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
              // First & Last name
              TextFormField(
                controller: _firstNameController,
                decoration: const InputDecoration(labelText: 'First Name*'),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _lastNameController,
                decoration: const InputDecoration(labelText: 'Last Name*'),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 8),

              // Phones
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
              TextFormField(
                controller: _phone2Controller,
                decoration: const InputDecoration(
                  labelText: 'Secondary Phone',
                  prefixText: '+',
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 8),

              // Email & Address
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(labelText: 'Address'),
                maxLines: 2,
              ),
              const SizedBox(height: 16),

              // Identification Photos with preview
              const Text(
                'Identification Photos',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Passport
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
                              ? Image.file(File(_passportPhoto!.path), fit: BoxFit.cover)
                              : (widget.customer?.passportPhotoUrl != null
                              ? Image.network(widget.customer!.passportPhotoUrl!, fit: BoxFit.cover)
                              : const Icon(Icons.add_a_photo, size: 40)),
                        ),
                      ),
                    ],
                  ),

                  // License
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
                              ? Image.file(File(_licensePhoto!.path), fit: BoxFit.cover)
                              : (widget.customer?.licensePhotoUrl != null
                              ? Image.network(widget.customer!.licensePhotoUrl!, fit: BoxFit.cover)
                              : const Icon(Icons.add_a_photo, size: 40)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Location inputs...
              const Text('Location', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _latController,
                      decoration: const InputDecoration(
                        labelText: 'Latitude',
                        prefixIcon: Icon(Icons.location_on),
                      ),
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
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
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                      onChanged: (_) => _updateLocationFromText(),
                    ),
                  ),
                ],
              ),
              if (!kIsWeb && (Platform.isAndroid || Platform.isIOS))
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: ElevatedButton(
                    onPressed: _getCurrentLocation,
                    child: const Text('Get Current Location'),
                  ),
                ),
              if (_currentPosition != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Current: ${_latController.text}, ${_lngController.text}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              const SizedBox(height: 16),

              // Google Maps URL converter...
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
              ElevatedButton(
                onPressed: _submitForm,
                style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
                child: const Text('Save Customer'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
