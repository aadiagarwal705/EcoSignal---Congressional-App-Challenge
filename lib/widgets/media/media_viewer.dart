import 'dart:async';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../../constants/app_theme.dart';
import '../../models/community_report.dart' show isVideoUrl;

Future<void> openMediaViewer(
  BuildContext context, {
  required List<String> urls,
  required int initialIndex,
}) {
  return Navigator.push(
    context,
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => MediaViewerScreen(urls: urls, initialIndex: initialIndex),
    ),
  );
}

class MediaViewerScreen extends StatefulWidget {
  final List<String> urls;
  final int initialIndex;

  const MediaViewerScreen({super.key, required this.urls, required this.initialIndex});

  @override
  State<MediaViewerScreen> createState() => _MediaViewerScreenState();
}

class _MediaViewerScreenState extends State<MediaViewerScreen> {
  late final _controller = PageController(initialPage: widget.initialIndex);
  late int _index = widget.initialIndex;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PageView.builder(
            controller: _controller,
            itemCount: widget.urls.length,
            onPageChanged: (i) => setState(() => _index = i),
            itemBuilder: (context, i) {
              final url = widget.urls[i];
              return isVideoUrl(url) ? _FullScreenVideo(url: url) : _FullScreenPhoto(url: url);
            },
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Spacer(),
                  if (widget.urls.length > 1)
                    Container(
                      margin: const EdgeInsets.only(right: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black45,
                        borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                      ),
                      child: Text(
                        '${_index + 1} / ${widget.urls.length}',
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FullScreenPhoto extends StatelessWidget {
  final String url;

  const _FullScreenPhoto({required this.url});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Image.network(
        url,
        fit: BoxFit.contain,
        loadingBuilder: (context, child, progress) =>
            progress == null ? child : const CircularProgressIndicator(color: Colors.white),
        errorBuilder: (context, error, stack) =>
            const Icon(Icons.broken_image_outlined, color: Colors.white54, size: 48),
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
  late final VideoPlayerController _controller;
  bool _ready = false;
  bool _showControls = true;
  Timer? _hideTimer;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url))
      ..addListener(_onTick)
      ..initialize().then((_) {
        if (!mounted) return;
        setState(() => _ready = true);
        _controller.play();
        _resetHideTimer();
      });
  }

  void _onTick() {
    if (mounted) setState(() {});
  }

  void _resetHideTimer() {
    _hideTimer?.cancel();
    if (_controller.value.isPlaying) {
      _hideTimer = Timer(const Duration(seconds: 3), () {
        if (mounted) setState(() => _showControls = false);
      });
    }
  }

  void _togglePlay() {
    if (_controller.value.isPlaying) {
      _controller.pause();
      _hideTimer?.cancel();
      setState(() => _showControls = true);
    } else {
      _controller.play();
      setState(() => _showControls = true);
      _resetHideTimer();
    }
  }

  void _seek(Duration offset) {
    final position = _controller.value.position + offset;
    final duration = _controller.value.duration;
    final clamped = position < Duration.zero
        ? Duration.zero
        : (position > duration ? duration : position);
    _controller.seekTo(clamped);
    setState(() => _showControls = true);
    _resetHideTimer();
  }

  void _toggleControls() {
    setState(() => _showControls = !_showControls);
    if (_showControls) _resetHideTimer();
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _controller.removeListener(_onTick);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const Center(child: CircularProgressIndicator(color: Colors.white));
    }
    return GestureDetector(
      onTap: _toggleControls,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Center(
            child: AspectRatio(
              aspectRatio: _controller.value.aspectRatio,
              child: VideoPlayer(_controller),
            ),
          ),
          AnimatedOpacity(
            opacity: _showControls ? 1 : 0,
            duration: const Duration(milliseconds: 200),
            child: IgnorePointer(
              ignoring: !_showControls,
              child: Container(
                color: Colors.black26,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.replay_10_rounded, color: Colors.white, size: 32),
                          onPressed: () => _seek(const Duration(seconds: -10)),
                        ),
                        const SizedBox(width: 20),
                        IconButton(
                          icon: Icon(
                            _controller.value.isPlaying
                                ? Icons.pause_circle_filled_rounded
                                : Icons.play_circle_fill_rounded,
                            color: Colors.white,
                            size: 62,
                          ),
                          onPressed: _togglePlay,
                        ),
                        const SizedBox(width: 20),
                        IconButton(
                          icon: const Icon(Icons.forward_10_rounded, color: Colors.white, size: 32),
                          onPressed: () => _seek(const Duration(seconds: 10)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: VideoProgressIndicator(
                        _controller,
                        allowScrubbing: true,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        colors: const VideoProgressColors(
                          playedColor: Colors.white,
                          bufferedColor: Colors.white30,
                          backgroundColor: Colors.white10,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
