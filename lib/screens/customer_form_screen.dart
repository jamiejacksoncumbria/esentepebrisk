import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:photo_view/photo_view.dart';
import 'package:uuid/uuid.dart';
import '../models/customer_model.dart';
import 'customer_search_screen.dart';

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

  XFile? _passportPhoto;
  XFile? _licensePhoto;
  Position? _currentPosition;
  bool _isLoading = false;
  bool _passportPhotoUpdated = false;
  bool _licensePhotoUpdated = false;

  @override
  void initState() {
    super.initState();
    if (widget.customer != null) {
      _initializeForm(widget.customer!);
    }
  }

  void _initializeForm(CustomerModel customer) {
    _firstNameController.text = customer.firstName;
    _lastNameController.text = customer.lastName;
    _phoneController.text = customer.phone;
    _phone2Controller.text = customer.secondaryPhone ?? '';
    _emailController.text = customer.email ?? '';
    _addressController.text = customer.address ?? '';
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
    super.dispose();
  }

  Future<void> _pickImage(bool isPassport) async {
    final picker = ImagePicker();

    Future<void> handlePick(ImageSource source) async {
      // Only request permissions for mobile platforms
      if (Platform.isAndroid || Platform.isIOS) {
        final permission = source == ImageSource.camera
            ? Permission.camera
            : (Platform.isIOS ? Permission.photos : Permission.storage);

        final status = await permission.request();
        if (!status.isGranted) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('${permission.toString().split('.').last} permission denied')),
            );
          }
          return;
        }
      }

      final picked = await picker.pickImage(source: source);
      if (picked != null) {
        final compressed = await compressImage(picked);
        if (compressed != null) {
          final compressedXFile = XFile(compressed.path);
          setState(() {
            if (isPassport) {
              _passportPhoto = compressedXFile;
              _passportPhotoUpdated = true;
            } else {
              _licensePhoto = compressedXFile;
              _licensePhotoUpdated = true;
            }
          });
        }
      }
    }

    // Handle Desktop: just open gallery, no modal or permissions
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      await handlePick(ImageSource.gallery);
      return;
    }

    // Handle Mobile: show modal to choose source
    final hasCamera = await Permission.camera.isGranted ||
        (await Permission.camera.request()).isGranted;

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Select from Gallery'),
              onTap: () async {
                Navigator.pop(context);
                await handlePick(ImageSource.gallery);
              },
            ),
            if (hasCamera)
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Take Photo'),
                onTap: () async {
                  Navigator.pop(context);
                  await handlePick(ImageSource.camera);
                },
              ),
          ],
        ),
      ),
    );
  }



  void _showPhotoPreview(String? url, XFile? file) {
    if (url == null && file == null) return;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: PhotoView(
          imageProvider: file != null
              ? FileImage(File(file.path))
              : NetworkImage(url!) as ImageProvider,
          minScale: PhotoViewComputedScale.contained,
          maxScale: PhotoViewComputedScale.covered * 2,
        ),
      ),
    );
  }

  Widget _buildPhotoWidget(String? url, bool isPassport) {
    final currentPhoto = isPassport ? _passportPhoto : _licensePhoto;
    final hasPhoto = url != null || currentPhoto != null;

    return GestureDetector(
      onLongPress: () => hasPhoto
          ? _showPhotoPreview(url, currentPhoto)
          : _pickImage(isPassport),
      onTap: () => _pickImage(isPassport),
      child: Container(
        height: 120,
        width: 120,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(8),
        ),
        child: hasPhoto
            ? currentPhoto != null
            ? Image.file(File(currentPhoto.path), fit: BoxFit.cover)
            : Image.network(url!, fit: BoxFit.cover)
            : const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_a_photo, size: 40),
            Text('Add Photo', style: TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoading = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location services are disabled')),
          );
          return;
        }
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Location permissions are denied')),
            );
            return;
          }
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location permissions are permanently denied'),
            ),
          );
          return;
        }
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentPosition = position;
        _latController.text = position.latitude.toStringAsFixed(6);
        _lngController.text = position.longitude.toStringAsFixed(6);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error getting location: ${e.toString()}')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _updateLocationFromText() {
    final lat = double.tryParse(_latController.text);
    final lng = double.tryParse(_lngController.text);

    if (lat != null && lng != null) {
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
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final repo = ref.read(customerRepositoryProvider);
      var customer =
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

      // Update customer data
      customer = customer.copyWith(
        firstName: _firstNameController.text,
        lastName: _lastNameController.text,
        phone: _phoneController.text,
        secondaryPhone: _phone2Controller.text.isEmpty
            ? null
            : _phone2Controller.text,
        email: _emailController.text.isEmpty ? null : _emailController.text,
        address: _addressController.text.isEmpty
            ? null
            : _addressController.text,
        location: _currentPosition == null
            ? null
            : GeoPoint(_currentPosition!.latitude, _currentPosition!.longitude),
        searchTerms: _generateSearchTerms(),
      );

      // Handle photo uploads
      if (_passportPhotoUpdated && _passportPhoto != null) {
        customer = customer.copyWith(
          passportPhotoUrl: await repo.uploadPhoto(
            customerId: customer.id,
            file: _passportPhoto!,
            type: 'passport',
          ),
        );
      }

      if (_licensePhotoUpdated && _licensePhoto != null) {
        customer = customer.copyWith(
          licensePhotoUrl: await repo.uploadPhoto(
            customerId: customer.id,
            file: _licensePhoto!,
            type: 'license',
          ),
        );
      }

      // Save to Firestore
      if (widget.customer == null) {
        await repo.createCustomer(customer);
      } else {
        await repo.updateCustomer(customer);
      }

      if (widget.onSave != null) widget.onSave!();
      if(mounted){Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context)=>CustomerSearchScreen(searchTerm: '${_firstNameController.text} ${_lastNameController.text}',)));}

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<String> _generateSearchTerms() {
    final terms = <String>[];

    void addTerms(String input) {
      if (input.length >= 3) {
        for (int i = 3; i <= input.length; i++) {
          terms.add(input.substring(0, i).toLowerCase());
        }
      }
    }

    addTerms(_firstNameController.text);
    addTerms('${_firstNameController.text}${_lastNameController.text}');
    addTerms('${_firstNameController.text} ${_lastNameController.text}');
    addTerms(_lastNameController.text);
    addTerms(_phoneController.text);
    if (_phone2Controller.text.isNotEmpty) addTerms(_phone2Controller.text);
    if (_emailController.text.isNotEmpty) {
      addTerms(_emailController.text);
    }
    if (_addressController.text.isNotEmpty) {
      _addressController.text.split(' ').forEach(addTerms);
    }

    return terms.toSet().toList();
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
            children: [
              TextFormField(
                controller: _firstNameController,
                decoration: const InputDecoration(
                  labelText: 'First Name*',
                ),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              TextFormField(
                controller: _lastNameController,
                decoration: const InputDecoration(
                  labelText: 'Last Name*',
                ),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone*',
                  prefixText: '+',
                ),
                keyboardType: TextInputType.phone,
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              TextFormField(
                controller: _phone2Controller,
                decoration: const InputDecoration(
                  labelText: 'Secondary Phone',
                  prefixText: '+',
                ),
                keyboardType: TextInputType.phone,
              ),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
              ),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(labelText: 'Address'),
                maxLines: 2,
              ),

              const SizedBox(height: 16),
              const Text(
                'Identification Photos',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Column(
                    children: [
                      const Text('Passport Photo'),
                      const SizedBox(height: 8),
                      _buildPhotoWidget(
                        widget.customer?.passportPhotoUrl,
                        true,
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      const Text('Driving License'),
                      const SizedBox(height: 8),
                      _buildPhotoWidget(
                        widget.customer?.licensePhotoUrl,
                        false,
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 16),
              const Text(
                'Location',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
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
                ],
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _getCurrentLocation,
                child: const Text('Get Current Location'),
              ),
              if (_currentPosition != null ||
                  widget.customer?.location != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Current: ${_currentPosition?.latitude.toStringAsFixed(6) ?? widget.customer?.location?.latitude.toStringAsFixed(6)}, '
                        '${_currentPosition?.longitude.toStringAsFixed(6) ?? widget.customer?.location?.longitude.toStringAsFixed(6)}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),

              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _submitForm,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Text('Save Customer'),
              ),
            ],
          ),
        ),
      ),
    );
  }
  Future<XFile?> compressImage(XFile file) async {
    final dir = await getTemporaryDirectory();
    final targetPath = '${dir.path}/${const Uuid().v4()}.jpg';

    final result = await FlutterImageCompress.compressAndGetFile(
      file.path,
      targetPath,
      quality: 70, // 70% is a good balance between size and quality
    );

    return result;
  }
}