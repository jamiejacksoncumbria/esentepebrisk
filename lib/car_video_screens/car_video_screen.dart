// lib/screens/car_video_screen.dart

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode, defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:photo_view/photo_view.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:video_player/video_player.dart';
import 'package:intl/intl.dart';

import '../models/car_model.dart';
import '../models/car_video_model.dart';
import '../providers/car_notifier.dart';
import '../providers/car_video_provider.dart';

class CarVideoScreen extends ConsumerStatefulWidget {
  static const routeName = '/car_video';
  final String customerId;
  const CarVideoScreen({Key? key, required this.customerId}) : super(key: key);

  @override
  ConsumerState<CarVideoScreen> createState() => _CarVideoScreenState();
}

class _CarVideoScreenState extends ConsumerState<CarVideoScreen> {
  final DateFormat _fmt = DateFormat('d MMM yyyy h:mma');

  Future<DateTime?> _pickDateTime() async {
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
  }

  Future<Car?> _selectCar() async {
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
    if (!mounted) return null;
    return chosen;
  }

  Future<void> _startFlow() async {
    final messenger = ScaffoldMessenger.of(context);

    // 1) pick date/time
    final dt = await _pickDateTime();
    if (dt == null) return;

    // 2) pick car
    final car = await _selectCar();
    if (car == null) return;

    // 3) permission
    if (!kIsWeb && !await Permission.camera.request().isGranted) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Camera permission denied')),
      );
      return;
    }

    final picker = ImagePicker();

    // 4) prompt for fuel photo
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Fuel Level'),
        content: const Text('Please take a picture of the fuel level'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
        ],
      ),
    );
    final XFile? fuel = await picker.pickImage(source: ImageSource.camera);
    if (fuel == null) return;

    // 5) prompt for video
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Car Video'),
        content: const Text('Please make a video of the car'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
        ],
      ),
    );
    final XFile? vid = await picker.pickVideo(source: ImageSource.camera);
    if (vid == null) return;

    messenger.showSnackBar(const SnackBar(content: Text('Uploading in background…')));
    _uploadMedia(dt, car, fuel, vid);
  }

  Future<void> _uploadMedia(DateTime dt, Car car, XFile fuel, XFile vid) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      // fuel image
      final imgBytes = await fuel.readAsBytes();
      final imgRef = FirebaseStorage.instance
          .ref('carVideos/${widget.customerId}/${dt.millisecondsSinceEpoch}_fuel.jpg');
      await imgRef.putData(imgBytes, SettableMetadata(contentType: 'image/jpeg'));
      final fuelUrl = await imgRef.getDownloadURL();

      // video
      final vidBytes = await vid.readAsBytes();
      final vidRef = FirebaseStorage.instance
          .ref('carVideos/${widget.customerId}/${dt.millisecondsSinceEpoch}.mp4');
      await vidRef.putData(vidBytes, SettableMetadata(contentType: 'video/mp4'));
      final videoUrl = await vidRef.getDownloadURL();

      final cv = CarVideo(
        id: '',
        customerId: widget.customerId,
        carId: car.id,
        timestamp: dt,
        fuelImageUrl: fuelUrl,
        videoUrl: videoUrl,
      );
      await ref.read(carVideoRepoProvider).addVideo(cv);

      if (mounted) {
        messenger.showSnackBar(const SnackBar(content: Text('Upload complete')));
      }
    } catch (e, st) {
      if (kDebugMode) debugPrint('[_uploadMedia] error: $e\n$st');
      if (mounted) messenger.showSnackBar(SnackBar(content: Text('Upload error: $e')));
    }
  }

  void _showImagePreview(String url) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        child: PhotoView(imageProvider: CachedNetworkImageProvider(url)),
      ),
    );
  }

  void _openFullScreenVideo(String url) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => FullScreenVideo(url: url),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final videosAsync = ref.watch(carVideosForCustomerProvider(widget.customerId));

    return Scaffold(
      appBar: AppBar(title: const Text('Car Videos & Fuel Level')),
      floatingActionButton: (!kIsWeb && defaultTargetPlatform == TargetPlatform.windows)
          ? null
          : FloatingActionButton(
        onPressed: _startFlow,
        child: const Icon(Icons.add),
      ),
      body: videosAsync.when(
        data: (videos) {
          if (videos.isEmpty) return const Center(child: Text('No videos yet.'));
          return ListView.builder(
            itemCount: videos.length,
            itemBuilder: (_, i) {
              final cv = videos[i];
              return ListTile(
                leading: cv.fuelImageUrl != null
                    ? GestureDetector(
                  onTap: () => _showImagePreview(cv.fuelImageUrl!),
                  child: CachedNetworkImage(
                    imageUrl: cv.fuelImageUrl!,
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => const SizedBox(
                      width: 50,
                      height: 50,
                      child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                    ),
                    errorWidget: (_, __, ___) => const Icon(Icons.error, size: 50),
                  ),
                )
                    : null,
                title: Text(_fmt.format(cv.timestamp)),
                trailing: IconButton(
                  icon: const Icon(Icons.play_arrow),
                  onPressed: () => _openFullScreenVideo(cv.videoUrl),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

/// Full-screen video player with play/pause and scrubbing
class FullScreenVideo extends StatefulWidget {
  final String url;
  const FullScreenVideo({Key? key, required this.url}) : super(key: key);

  @override
  FullScreenVideoState createState() => FullScreenVideoState();
}

class FullScreenVideoState extends State<FullScreenVideo> {
  late VideoPlayerController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = VideoPlayerController.networkUrl(Uri.parse(widget.url))
      ..initialize().then((_) => setState(() {}))
      ..setLooping(true)
      ..play();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(backgroundColor: Colors.black),
      body: Center(
        child: _ctrl.value.isInitialized
            ? AspectRatio(
          aspectRatio: _ctrl.value.aspectRatio,
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              VideoPlayer(_ctrl),
              VideoProgressIndicator(_ctrl, allowScrubbing: true),
              Center(
                child: IconButton(
                  icon: Icon(
                    _ctrl.value.isPlaying ? Icons.pause : Icons.play_arrow,
                    color: Colors.white,
                    size: 48,
                  ),
                  onPressed: () => setState(() {
                    _ctrl.value.isPlaying ? _ctrl.pause() : _ctrl.play();
                  }),
                ),
              ),
            ],
          ),
        )
            : const CircularProgressIndicator(),
      ),
    );
  }
}
