import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

/// Lentadagi post/hikoyadagi video uchun to'liq ekranli pleer —
/// tarmoq URL'idan to'g'ridan-to'g'ri ijro etadi (Supabase Storage'da
/// saqlangan). Oddiy: play/pause + orqaga qaytish, murakkab boshqaruv
/// paneli (tezlik, subtitr va h.k.) kerak emas — bu ijtimoiy lenta
/// videosi, professional pleer emas.
class VideoPlayerScreen extends StatefulWidget {
  final String videoUrl;
  const VideoPlayerScreen({super.key, required this.videoUrl});

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late final VideoPlayerController _controller;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
      ..initialize().then((_) {
        if (!mounted) return;
        setState(() {});
        _controller.play();
      }).catchError((_) {
        if (mounted) setState(() => _hasError = true);
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: _hasError
                  ? const Text(
                      'Video ochilmadi',
                      style: TextStyle(color: Colors.white),
                    )
                  : _controller.value.isInitialized
                      ? GestureDetector(
                          onTap: () => setState(() {
                            _controller.value.isPlaying
                                ? _controller.pause()
                                : _controller.play();
                          }),
                          child: AspectRatio(
                            aspectRatio: _controller.value.aspectRatio,
                            child: VideoPlayer(_controller),
                          ),
                        )
                      : const CircularProgressIndicator(color: Colors.white),
            ),
            Positioned(
              top: 8,
              left: 8,
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close, color: Colors.white, size: 28),
              ),
            ),
            if (_controller.value.isInitialized && !_controller.value.isPlaying)
              const Center(
                child: Icon(Icons.play_circle_fill_rounded,
                    color: Colors.white70, size: 64),
              ),
          ],
        ),
      ),
    );
  }
}
