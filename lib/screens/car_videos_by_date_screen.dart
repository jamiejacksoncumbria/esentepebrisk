import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:photo_view/photo_view.dart';
import 'package:video_player/video_player.dart';
import 'package:intl/intl.dart';

import '../models/car_video_model.dart';
import '../providers/car_video_provider.dart';

class CarVideosByDateScreen extends ConsumerStatefulWidget {
  static const routeName = '/car_videos_by_date';
  const CarVideosByDateScreen({Key? key}) : super(key: key);

  @override
  _CarVideosByDateScreenState createState() => _CarVideosByDateScreenState();
}

class _CarVideosByDateScreenState
    extends ConsumerState<CarVideosByDateScreen> {
  DateTime? _startDate, _endDate;
  final _dateFmt = DateFormat('d MMM yyyy');

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
        _endDate = DateTime(date.year, date.month, date.day, 23, 59, 59);
      }
    });
  }

  void _showImage(String url) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        child: PhotoView(imageProvider: CachedNetworkImageProvider(url)),
      ),
    );
  }

  void _openVideo(String url) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => _FullScreenVideo(url: url),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final range = (_startDate != null && _endDate != null)
        ? DateRange(start: _startDate!, end: _endDate!)
        : null;

    return Scaffold(
      appBar: AppBar(title: const Text('Car Videos by Date Range')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          Row(children: [
            Expanded(
              child: ListTile(
                title: Text(_startDate == null
                    ? 'Select Start'
                    : _dateFmt.format(_startDate!)),
                onTap: () => _pickDate(isStart: true),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ListTile(
                title: Text(_endDate == null
                    ? 'Select End'
                    : _dateFmt.format(_endDate!)),
                onTap: () => _pickDate(isStart: false),
              ),
            ),
          ]),
          const SizedBox(height: 16),
          if (range == null)
            const Text('Please select both dates'),
          if (range != null)
            Expanded(
              child: ref.watch(carVideosBetweenDatesProvider(range)).when(
                data: (videos) {
                  if (videos.isEmpty) {
                    return const Center(child: Text('No videos found'));
                  }
                  return ListView.separated(
                    separatorBuilder: (_,__) => const Divider(),
                    itemCount: videos.length,
                    itemBuilder: (_, i) {
                      final cv = videos[i];
                      return ListTile(
                        leading: cv.fuelImageUrl != null
                            ? GestureDetector(
                          onTap: () => _showImage(cv.fuelImageUrl!),
                          child: CachedNetworkImage(
                            imageUrl: cv.fuelImageUrl!,
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                            placeholder: (_, __) =>
                            const CircularProgressIndicator(strokeWidth: 2),
                            errorWidget: (_, __, ___) =>
                            const Icon(Icons.error),
                          ),
                        )
                            : null,
                        title: Text(DateFormat('d MMM yyyy h:mma')
                            .format(cv.timestamp)),
                        trailing: IconButton(
                          icon: const Icon(Icons.play_arrow),
                          onPressed: () => _openVideo(cv.videoUrl),
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error: $e')),
              ),
            ),
        ]),
      ),
    );
  }
}

/// reused full‐screen player
class _FullScreenVideo extends StatefulWidget {
  final String url;
  const _FullScreenVideo({Key? key, required this.url}) : super(key: key);

  @override
  __FullScreenVideoState createState() => __FullScreenVideoState();
}

class __FullScreenVideoState extends State<_FullScreenVideo> {
  late VideoPlayerController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = VideoPlayerController.networkUrl(Uri.parse(widget.url))
      ..initialize().then((_) => setState(() {}))
      ..setLooping(false)
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
            ? Stack(
          alignment: Alignment.bottomCenter,
          children: [
            AspectRatio(
              aspectRatio: _ctrl.value.aspectRatio,
              child: VideoPlayer(_ctrl),
            ),
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
        )
            : const CircularProgressIndicator(),
      ),
    );
  }
}
