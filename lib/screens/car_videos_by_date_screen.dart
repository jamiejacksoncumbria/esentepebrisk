// lib/car_video_screens/car_videos_by_date_screen.dart

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:photo_view/photo_view.dart';
import 'package:video_player/video_player.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';

import '../models/car_video_model.dart';
import '../providers/car_video_provider.dart';

class CarVideosByDateScreen extends ConsumerStatefulWidget {
  static const routeName = '/view_car_videos';
  const CarVideosByDateScreen({super.key});

  @override
  ConsumerState<CarVideosByDateScreen> createState() =>
      _CarVideosByDateScreenState();
}

class _CarVideosByDateScreenState
    extends ConsumerState<CarVideosByDateScreen> {
  DateTime? _startDate;
  DateTime? _endDate;
  final DateFormat _dateFmt = DateFormat('d MMM yyyy');
  final DateFormat _tsFmt = DateFormat('d MMM yyyy h:mma');

  Future<void> _pickDate({required bool isStart}) async {
    final now = DateTime.now();
    final initial = isStart
        ? (_startDate ?? now)
        : (_endDate ?? now);
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (date == null || !mounted) return;

    setState(() {
      if (isStart) {
        _startDate = DateTime(date.year, date.month, date.day);
      } else {
        _endDate = DateTime(date.year, date.month, date.day, 23, 59, 59, 999);
      }
    });
  }

  Future<void> _showImageZoom(String url) async {
    if (!mounted) return;
    await showDialog<void>(
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

  Future<void> _playVideo(String url) async {
    // On Web or Windows, just open URL externally:
    if (kIsWeb || defaultTargetPlatform == TargetPlatform.windows) {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
      return;
    }

    // Otherwise, use in-app video_player:
    final controller = VideoPlayerController.networkUrl(Uri.parse(url));
    await controller.initialize();
    controller.play();

    if (!mounted) {
      controller.dispose();
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) {
        return Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(backgroundColor: Colors.transparent),
          body: Center(
            child: AspectRatio(
              aspectRatio: controller.value.aspectRatio,
              child: VideoPlayer(controller),
            ),
          ),
          floatingActionButton: FloatingActionButton(
            backgroundColor: Colors.white70,
            onPressed: () {
              setState(() {
                controller.value.isPlaying
                    ? controller.pause()
                    : controller.play();
              });
            },
            child: Icon(
              controller.value.isPlaying
                  ? Icons.pause
                  : Icons.play_arrow,
              color: Colors.black,
            ),
          ),
        );
      }),
    );

    controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final repo = ref.read(carVideoRepoProvider);
    Stream<List<CarVideo>>? stream;
    if (_startDate != null && _endDate != null) {
      stream = repo.streamBetweenDates(_startDate!, _endDate!);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('View Car Videos')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: ListTile(
                    title: Text(_startDate == null
                        ? 'Select Start Date'
                        : _dateFmt.format(_startDate!)),
                    onTap: () => _pickDate(isStart: true),
                  ),
                ),
                Expanded(
                  child: ListTile(
                    title: Text(_endDate == null
                        ? 'Select End Date'
                        : _dateFmt.format(_endDate!)),
                    onTap: () => _pickDate(isStart: false),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (stream == null)
              const Text('Please pick both start & end dates'),
            if (stream != null)
              Expanded(
                child: StreamBuilder<List<CarVideo>>(
                  stream: stream,
                  builder: (ctx, snap) {
                    if (snap.hasError) {
                      return Center(child: Text('Error: ${snap.error}'));
                    }
                    if (!snap.hasData) {
                      return const Center(
                          child: CircularProgressIndicator());
                    }
                    final videos = snap.data!;
                    if (videos.isEmpty) {
                      return const Center(
                          child: Text('No videos in this range.'));
                    }
                    return ListView.builder(
                      itemCount: videos.length,
                      itemBuilder: (_, i) {
                        final cv = videos[i];
                        return ListTile(
                          leading: cv.fuelImageUrl != null
                              ? GestureDetector(
                            onTap: () =>
                                _showImageZoom(cv.fuelImageUrl!),
                            child: CachedNetworkImage(
                              imageUrl: cv.fuelImageUrl!,
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                              placeholder: (_, _) =>
                              const SizedBox(
                                width: 50,
                                height: 50,
                                child: Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              ),
                              errorWidget: (_, _, _) =>
                              const Icon(Icons.error_outline),
                            ),
                          )
                              : null,
                          title: Text(_tsFmt.format(cv.timestamp)),
                          subtitle: Text('Car: ${cv.carId}'),
                          trailing: IconButton(
                            icon: const Icon(Icons.play_arrow),
                            onPressed: () => _playVideo(cv.videoUrl),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
