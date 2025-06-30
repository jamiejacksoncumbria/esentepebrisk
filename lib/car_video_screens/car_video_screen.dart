// lib/car_video_screens/car_video_screen.dart

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  const CarVideoScreen({super.key, required this.customerId});

  @override
  ConsumerState<CarVideoScreen> createState() => _CarVideoScreenState();
}

class _CarVideoScreenState extends ConsumerState<CarVideoScreen> {
  final DateFormat _fmt = DateFormat('d MMM yyyy h:mma');

  /// Prompt for date/time
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

  /// Prompt to select a car
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

  /// Full flow: date/time → car → fuel photo → video → enqueue upload
  Future<void> _startFlow() async {
    final messenger = ScaffoldMessenger.of(context);

    // 1) Pick date/time
    final dt = await _pickDateTime();
    if (dt == null) return;

    // 2) Pick car
    final car = await _selectCar();
    if (car == null) return;

    // 3) Check camera permission
    if (!kIsWeb && !await Permission.camera.request().isGranted) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Camera permission denied')),
      );
      return;
    }

    final picker = ImagePicker();

    // 4) Prompt for fuel photo
    if(!mounted){return;}
    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Fuel Level'),
        content: const Text('Please take a picture of the fuel level'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );

    final XFile? fuelImage =
    await picker.pickImage(source: ImageSource.camera);
    if (fuelImage == null) return;

    // 5) Prompt for car video
    if(!mounted){return;}

    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Car Video'),
        content: const Text('Please make a video of the car'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );

    final XFile? videoFile =
    await picker.pickVideo(source: ImageSource.camera);
    if (videoFile == null) return;

    // 6) Notify and background-upload
    messenger.showSnackBar(
      const SnackBar(content: Text('Uploading in background…')),
    );
    _uploadMedia(dt, car, fuelImage, videoFile);
  }

  /// Background upload both media, then Firestore
  Future<void> _uploadMedia(
      DateTime dt, Car car, XFile fuel, XFile vid) async {
    final messenger = ScaffoldMessenger.of(context);

    try {
      // Upload fuel image
      final imgBytes = await fuel.readAsBytes();
      final imgRef = FirebaseStorage.instance
          .ref('carVideos/${widget.customerId}/${dt.millisecondsSinceEpoch}_fuel.jpg');
      await imgRef.putData(imgBytes,
          SettableMetadata(contentType: 'image/jpeg'));
      final imgUrl = await imgRef.getDownloadURL();

      // Upload video
      final vidBytes = await vid.readAsBytes();
      final vidRef = FirebaseStorage.instance
          .ref('carVideos/${widget.customerId}/${dt.millisecondsSinceEpoch}.mp4');
      await vidRef.putData(vidBytes,
          SettableMetadata(contentType: 'video/mp4'));
      final vidUrl = await vidRef.getDownloadURL();

      // Firestore record
      final cv = CarVideo(
        id: '',
        customerId: widget.customerId,
        carId: car.id,
        timestamp: dt,
        videoUrl: vidUrl,
        fuelImageUrl: imgUrl,
      );
      await ref.read(carVideoRepoProvider).addVideo(cv);

      if (mounted) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Upload complete')),
        );
      }
    } catch (e, st) {
      if (kDebugMode) debugPrint('[_uploadMedia] error: $e\n$st');
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text('Upload error: $e')),
        );
      }
    }
  }

  /// Play the stored video in full-screen with controls
  Future<void> _playVideo(String url) async {
    final controller = VideoPlayerController.networkUrl(Uri.parse(url));
    await controller.initialize();

    if (!mounted) {
      controller.dispose();
      return;
    }

    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        content: AspectRatio(
          aspectRatio: controller.value.aspectRatio,
          child: VideoPlayer(controller),
        ),
        actions: [
          IconButton(
            icon: Icon(
              controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
            ),
            onPressed: () {
              setState(() {
                controller.value.isPlaying
                    ? controller.pause()
                    : controller.play();
              });
            },
          ),
        ],
      ),
    ).then((_) => controller.dispose());
  }

  @override
  Widget build(BuildContext context) {
    final videosAsync =
    ref.watch(carVideosForCustomerProvider(widget.customerId));

    return Scaffold(
      appBar: AppBar(title: const Text('Car Videos & Fuel Level')),
      floatingActionButton: kIsWeb || !(Theme.of(context).platform == TargetPlatform.windows)
          ? FloatingActionButton(
        onPressed: _startFlow,
        child: const Icon(Icons.add),
      )
          : null,
      body: videosAsync.when(
        data: (list) {
          if (list.isEmpty) {
            return const Center(child: Text('No videos yet.'));
          }
          return ListView.builder(
            itemCount: list.length,
            itemBuilder: (_, i) {
              final cv = list[i];
              return ListTile(
                leading: cv.fuelImageUrl != null
                    ? Image.network(
                  cv.fuelImageUrl!,
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                )
                    : null,
                title: Text(_fmt.format(cv.timestamp)),
                subtitle: Text('Car: ${cv.carId}'),
                trailing: IconButton(
                  icon: const Icon(Icons.play_arrow),
                  onPressed: () => _playVideo(cv.videoUrl),
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
