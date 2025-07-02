// lib/screens/car_videos_by_date_screen.dart

import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:photo_view/photo_view.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';
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
  final DateFormat _tsFmt   = DateFormat('d MMM yyyy h:mma');

  Future<void> _pick({required bool isStart}) async {
    final now = DateTime.now();
    final initial = isStart
        ? (_startDate ?? now)
        : (_endDate ?? now);
    final d = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate:  DateTime(2100),
    );
    if (d == null || !mounted) return;
    setState(() {
      if (isStart) {
        // midnight start
        _startDate = DateTime(d.year, d.month, d.day);
      } else {
        // end of day
        _endDate = DateTime(d.year, d.month, d.day, 23, 59, 59);
      }
    });
  }

  Future<void> _showImage(String url) async {
    if (!mounted) return;
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

  Future<void> _play(String url) async {
    // On Windows just open in browser/app:
    if (!kIsWeb && Platform.isWindows) {
      await launchUrl(Uri.parse(url),
          mode: LaunchMode.externalApplication);
      return;
    }

    final ctrl = VideoPlayerController.networkUrl(Uri.parse(url));
    try {
      await ctrl.initialize();
      if (!mounted) {
        ctrl.dispose();
        return;
      }
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          content: AspectRatio(
            aspectRatio: ctrl.value.aspectRatio,
            child: VideoPlayer(ctrl),
          ),
          actions: [
            IconButton(
              icon: Icon(
                ctrl.value.isPlaying
                    ? Icons.pause
                    : Icons.play_arrow,
              ),
              onPressed: () {
                setState(() {
                  ctrl.value.isPlaying
                      ? ctrl.pause()
                      : ctrl.play();
                });
              },
            ),
          ],
        ),
      ).then((_) => ctrl.dispose());
    } catch (e) {
      if (kDebugMode) debugPrint('video init error: $e');
      ctrl.dispose();
    }
  }

  @override
  Widget build(BuildContext c) {
    final repo = ref.read(carVideoRepoProvider);
    Stream<List<CarVideo>>? stream;
    if (_startDate != null && _endDate != null) {
      stream = repo.streamBetweenDates(_startDate!, _endDate!);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Car Videos by Date')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(children: [
              Expanded(
                child: ListTile(
                  title: Text(
                    _startDate == null
                        ? 'Start Date'
                        : _dateFmt.format(_startDate!),
                  ),
                  onTap: () => _pick(isStart: true),
                ),
              ),
              Expanded(
                child: ListTile(
                  title: Text(
                    _endDate == null
                        ? 'End Date'
                        : _dateFmt.format(_endDate!),
                  ),
                  onTap: () => _pick(isStart: false),
                ),
              ),
            ]),
            const SizedBox(height: 16),
            if (stream == null)
              const Text('Please pick both dates to load videos.')
            else
              Expanded(
                child: StreamBuilder<List<CarVideo>>(
                  stream: stream,
                  builder: (_, snap) {
                    if (snap.hasError) {
                      return Center(child: Text('Error: ${snap.error}'));
                    }
                    if (!snap.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final list = snap.data!;
                    if (list.isEmpty) {
                      return const Center(child: Text('No videos in range.'));
                    }
                    return ListView.builder(
                      itemCount: list.length,
                      itemBuilder: (_, i) {
                        final cv = list[i];
                        return ListTile(
                          leading: cv.fuelImageUrl != null
                              ? GestureDetector(
                            onTap: () => _showImage(cv.fuelImageUrl!),
                            child: CachedNetworkImage(
                              imageUrl: cv.fuelImageUrl!,
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                            ),
                          )
                              : null,
                          title: Text(_tsFmt.format(cv.timestamp)),
                          subtitle: Text('Car ID: ${cv.carId}'),
                          trailing: IconButton(
                            icon: const Icon(Icons.play_arrow),
                            onPressed: () => _play(cv.videoUrl),
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
