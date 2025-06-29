// lib/screens/car_video_screen.dart

import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode, debugPrint;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:video_player/video_player.dart';
import 'package:intl/intl.dart';
import 'package:photo_view/photo_view.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/car_model.dart';
import '../models/car_video_model.dart';
import '../providers/car_notifier.dart';
import '../providers/car_video_provider.dart';

class CarVideoScreen extends ConsumerStatefulWidget {
  static const routeName = '/car_video';
  final String customerId;
  const CarVideoScreen({super.key, required this.customerId});

  @override
  ConsumerState<CarVideoScreen> createState() => _CarVideoScreenState();
}

class _CarVideoScreenState extends ConsumerState<CarVideoScreen> {
  final DateFormat _fmt = DateFormat('d MMM yyyy h:mma');

  Future<DateTime?> _pickDateTime() async {
    try {
      final now = DateTime.now();
      final date = await showDatePicker(
        context: context,
        initialDate: now,
        firstDate: DateTime(2000),
        lastDate: DateTime(2100),
      );
      if (date == null || !mounted) return null;
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(now),
      );
      if (time == null || !mounted) return null;
      return DateTime(date.year, date.month, date.day, time.hour, time.minute);
    } catch (e, st) {
      if (kDebugMode) debugPrint('[_pickDateTime] error: $e\n$st');
      return null;
    }
  }

  Future<Car?> _selectCar() async {
    try {
      final cars = await ref.read(carsStreamProvider.future);
      if (!mounted) return null;
      Car? chosen;
      await showDialog<void>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Select Car'),
          content: DropdownButton<Car>(
            isExpanded: true,
            value: cars.isNotEmpty ? cars.first : null,
            items: cars
                .map((c) => DropdownMenuItem(
              value: c,
              child: Text('${c.registration} ${c.make} ${c.model}'),
            ))
                .toList(),
            onChanged: (c) {
              chosen = c;
              Navigator.pop(context);
            },
          ),
        ),
      );
      return chosen;
    } catch (e, st) {
      if (kDebugMode) debugPrint('[_selectCar] error: $e\n$st');
      return null;
    }
  }

  Future<void> _startFlow() async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final dt = await _pickDateTime();
      if (dt == null) return;

      final car = await _selectCar();
      if (car == null) return;

      final picker = ImagePicker();
      final camOk = kIsWeb || await Permission.camera.request().isGranted;
      if (!camOk) {
        messenger.showSnackBar(const SnackBar(content: Text('Camera permission denied')));
        return;
      }

      final XFile? fuelImage = await picker.pickImage(source: ImageSource.camera);
      if (fuelImage == null) return;

      final XFile? videoFile = await picker.pickVideo(source: ImageSource.camera);
      if (videoFile == null) return;

      messenger.showSnackBar(const SnackBar(content: Text('Uploading in background…')));
      _uploadMedia(dt, car, fuelImage, videoFile);
    } catch (e, st) {
      if (kDebugMode) debugPrint('[_startFlow] error: $e\n$st');
    }
  }

  Future<void> _uploadMedia(DateTime dt, Car car, XFile fuel, XFile vid) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final imgBytes = await fuel.readAsBytes();
      final imgRef = FirebaseStorage.instance
          .ref('carVideos/${widget.customerId}/${dt.millisecondsSinceEpoch}_fuel.jpg');
      await imgRef.putData(imgBytes, SettableMetadata(contentType: 'image/jpeg'));
      final imgUrl = await imgRef.getDownloadURL();

      final vidBytes = await vid.readAsBytes();
      final vidRef = FirebaseStorage.instance
          .ref('carVideos/${widget.customerId}/${dt.millisecondsSinceEpoch}.mp4');
      await vidRef.putData(vidBytes, SettableMetadata(contentType: 'video/mp4'));
      final vidUrl = await vidRef.getDownloadURL();

      final cv = CarVideo(
        id: '',
        customerId: widget.customerId,
        carId: car.id,
        timestamp: dt,
        videoUrl: vidUrl,
        fuelImageUrl: imgUrl,
      );
      await ref.read(carVideoRepoProvider).addVideo(cv);

      if (mounted) messenger.showSnackBar(const SnackBar(content: Text('Upload complete')));
    } catch (e, st) {
      if (kDebugMode) debugPrint('[_uploadMedia] error: $e\n$st');
      if (mounted) messenger.showSnackBar(SnackBar(content: Text('Background upload error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final carsAsync = ref.watch(carsStreamProvider);
    final videosAsync = ref.watch(carVideosForCustomerProvider(widget.customerId));

    return Scaffold(
      appBar: AppBar(title: const Text('Car Videos & Fuel Level')),
      floatingActionButton: Platform.isWindows
          ? null
          : FloatingActionButton(
        onPressed: _startFlow,
        child: const Icon(Icons.add),
      ),
      body: videosAsync.when(
        data: (videos) {
          if (videos.isEmpty) return const Center(child: Text('No videos yet.'));
          return carsAsync.when(
            data: (cars) {
              return ListView.builder(
                itemCount: videos.length,
                itemBuilder: (_, i) {
                  final cv = videos[i];
                  final car = cars.firstWhere(
                        (c) => c.id == cv.carId,
                    orElse: () => Car(id: cv.carId, make: '', model: '', registration: cv.carId),
                  );
                  return ListTile(
                    leading: cv.fuelImageUrl != null
                        ? GestureDetector(
                      onTap: () => showDialog(
                        context: context,
                        builder: (_) => Dialog(
                          child: PhotoView(
                            imageProvider: NetworkImage(cv.fuelImageUrl!),
                            backgroundDecoration: const BoxDecoration(color: Colors.white),
                          ),
                        ),
                      ),
                      child: CachedNetworkImage(
                        imageUrl: cv.fuelImageUrl!,
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                        placeholder: (ctx, url) => const SizedBox(
                          width: 50, height: 50,
                          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                        ),
                        errorWidget: (ctx, url, err) => const Icon(Icons.broken_image, size: 50),
                      ),
                    )
                        : null,
                    title: Text(_fmt.format(cv.timestamp)),
                    subtitle: Text('Car: ${car.registration}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.play_arrow),
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => _FullScreenVideo(url: cv.videoUrl)),
                      ),
                    ),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error loading cars: $e')),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error loading videos: $e')),
      ),
    );
  }
}

class _FullScreenVideo extends StatefulWidget {
  final String url;
  const _FullScreenVideo({required this.url});

  @override
  State<_FullScreenVideo> createState() => _FullScreenVideoState();
}

class _FullScreenVideoState extends State<_FullScreenVideo> {
  late final VideoPlayerController _ctrl;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    if (Platform.isWindows) {
      // Fallback: open externally
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final uri = Uri.parse(widget.url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
        if (mounted) Navigator.pop(context);
      });
      return;
    }
    _ctrl = VideoPlayerController.networkUrl(Uri.parse(widget.url))
      ..initialize().then((_) {
        if (!mounted) return;
        final sz = _ctrl.value.size;
        SystemChrome.setPreferredOrientations(
          sz.width > sz.height
              ? [DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]
              : [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown],
        );
        setState(() => _loading = false);
        _ctrl.play();
      }).catchError((e, st) {
        if (kDebugMode) debugPrint('[_FullScreenVideo init] error: $e\n$st');
        if (mounted) Navigator.pop(context);
      });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Center(
          child: _loading
              ? const CircularProgressIndicator()
              : Stack(
            alignment: Alignment.bottomCenter,
            children: [
              GestureDetector(
                onTap: () => setState(() {
                  _ctrl.value.isPlaying ? _ctrl.pause() : _ctrl.play();
                }),
                child: AspectRatio(
                  aspectRatio: _ctrl.value.aspectRatio,
                  child: VideoPlayer(_ctrl),
                ),
              ),
              VideoProgressIndicator(_ctrl, allowScrubbing: true, padding: const EdgeInsets.all(12)),
            ],
          ),
        ),
      ),
      floatingActionButton: _loading || Platform.isWindows
          ? null
          : FloatingActionButton(
        backgroundColor: Colors.white70,
        child: Icon(_ctrl.value.isPlaying ? Icons.pause : Icons.play_arrow, color: Colors.black),
        onPressed: () => setState(() {
          _ctrl.value.isPlaying ? _ctrl.pause() : _ctrl.play();
        }),
      ),
    );
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    if (!Platform.isWindows) _ctrl.dispose();
    super.dispose();
  }
}
