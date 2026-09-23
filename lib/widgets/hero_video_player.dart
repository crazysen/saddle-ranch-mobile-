import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:video_player/video_player.dart';

class HeroVideoItem {
  final String title;
  final String subtitle;
  final String assetPath;

  const HeroVideoItem({
    required this.title,
    required this.subtitle,
    required this.assetPath,
  });
}

/// Sizzling Hero Video Player matching Saddle Ranch Web Hero videos
/// Cycles smoothly: Video 1 -> Video 2 -> Video 3 -> Video 4 -> Video 1
class HeroVideoPlayer extends StatefulWidget {
  final VoidCallback? onTap;

  const HeroVideoPlayer({super.key, this.onTap});

  @override
  State<HeroVideoPlayer> createState() => _HeroVideoPlayerState();
}

class _HeroVideoPlayerState extends State<HeroVideoPlayer> {
  static const List<HeroVideoItem> _videos = [
    HeroVideoItem(
      title: 'Sizzling Porkchop',
      subtitle: 'Cast-Iron Roadhouse Favorite',
      assetPath: 'assets/videos/porkchop.mp4',
    ),
    HeroVideoItem(
      title: 'Crispy Sisig',
      subtitle: 'Piping Hot with Egg & Calamansi',
      assetPath: 'assets/videos/sisig.mp4',
    ),
    HeroVideoItem(
      title: 'Spicy Beef',
      subtitle: 'Tender Slices with Savory Gravy',
      assetPath: 'assets/videos/spicy_beef.mp4',
    ),
    HeroVideoItem(
      title: 'Signature Tapsilog',
      subtitle: 'Charcoal Seared Classic',
      assetPath: 'assets/videos/tapsilog.mp4',
    ),
  ];

  int _currentIndex = 0;
  VideoPlayerController? _controller;
  bool _isInitializing = true;
  bool _isMuted = true;
  bool _isPlaying = true;
  bool _showControls = false;
  Timer? _controlsTimer;

  @override
  void initState() {
    super.initState();
    _initVideo(_currentIndex);
  }

  Future<void> _initVideo(int index) async {
    setState(() {
      _isInitializing = true;
    });

    final oldController = _controller;
    _controller = null;
    if (oldController != null) {
      await oldController.dispose();
    }

    if (!mounted) return;

    final item = _videos[index];
    final controller = VideoPlayerController.asset(item.assetPath);

    try {
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }

      await controller.setVolume(_isMuted ? 0.0 : 1.0);
      await controller.setLooping(false);
      await controller.play();

      controller.addListener(_videoListener);

      setState(() {
        _controller = controller;
        _currentIndex = index;
        _isInitializing = false;
        _isPlaying = true;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isInitializing = false;
      });
      // Fallback: advance to next video if error occurs
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) _playNext();
      });
    }
  }

  void _videoListener() {
    final c = _controller;
    if (c == null || !c.value.isInitialized) return;

    if (c.value.position >= c.value.duration && !c.value.isPlaying) {
      _playNext();
    }
  }

  void _playNext() {
    final next = (_currentIndex + 1) % _videos.length;
    _initVideo(next);
  }

  void _togglePlayPause() {
    final c = _controller;
    if (c == null || !c.value.isInitialized) return;

    setState(() {
      if (c.value.isPlaying) {
        c.pause();
        _isPlaying = false;
      } else {
        c.play();
        _isPlaying = true;
      }
      _showControls = true;
    });
    _resetControlsTimer();
  }

  void _toggleMute() {
    final c = _controller;
    setState(() {
      _isMuted = !_isMuted;
      c?.setVolume(_isMuted ? 0.0 : 1.0);
      _showControls = true;
    });
    _resetControlsTimer();
  }

  void _resetControlsTimer() {
    _controlsTimer?.cancel();
    _controlsTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() => _showControls = false);
      }
    });
  }

  @override
  void dispose() {
    _controlsTimer?.cancel();
    final c = _controller;
    _controller = null;
    c?.removeListener(_videoListener);
    c?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final current = _videos[_currentIndex];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF141416),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF31281F), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Video Layer
            if (!_isInitializing && _controller != null && _controller!.value.isInitialized)
              FittedBox(
                fit: BoxFit.cover,
                clipBehavior: Clip.hardEdge,
                child: SizedBox(
                  width: _controller!.value.size.width,
                  height: _controller!.value.size.height,
                  child: VideoPlayer(_controller!),
                ),
              )
            else
              Container(
                color: const Color(0xFF1C150E),
                child: Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: const Color(0xFFFFA000),
                  ),
                ),
              ),

            // Top Vignette Gradient Overlay
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 60,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.7),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // Bottom Vignette Gradient Overlay
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: 80,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.85),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // Top Header: Badge & Mute Toggle
            Positioned(
              top: 10,
              left: 12,
              right: 12,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1C150E).withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.6)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(LucideIcons.flame, size: 12, color: Color(0xFFF59E0B)),
                        const SizedBox(width: 4),
                        Text(
                          'ROADHOUSE SIZZLER',
                          style: GoogleFonts.inter(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                            color: const Color(0xFFFFC174),
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: _toggleMute,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white24),
                      ),
                      child: Icon(
                        _isMuted ? LucideIcons.volumeX : LucideIcons.volume2,
                        size: 14,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Bottom Info: Title, Subtitle, & Video Dots
            Positioned(
              bottom: 10,
              left: 12,
              right: 12,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          current.title,
                          style: GoogleFonts.domine(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFFFFC174),
                            shadows: const [
                              Shadow(color: Colors.black, blurRadius: 6, offset: Offset(0, 1)),
                            ],
                          ),
                        ),
                        Text(
                          current.subtitle,
                          style: GoogleFonts.inter(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFFF0E0D1),
                            shadows: const [
                              Shadow(color: Colors.black, blurRadius: 4),
                            ],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),

                  // Indicator Dots
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(_videos.length, (i) {
                      final isActive = i == _currentIndex;
                      return GestureDetector(
                        onTap: () => _initVideo(i),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.only(left: 4),
                          width: isActive ? 16 : 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: isActive ? const Color(0xFFF59E0B) : Colors.white38,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),

            // Center Tap Area for Play / Pause
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _togglePlayPause,
                child: _showControls || !_isPlaying
                    ? Center(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.65),
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.7)),
                          ),
                          child: Icon(
                            _isPlaying ? LucideIcons.pause : LucideIcons.play,
                            size: 26,
                            color: const Color(0xFFFFC174),
                          ),
                        ),
                      )
                    : const SizedBox.expand(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
