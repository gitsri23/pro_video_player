import 'dart:async';
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

// --- Premium Glass Widget ---
class PremiumGlass extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;

  const PremiumGlass({Key? key, required this.child, this.borderRadius = 30.0, this.padding}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 25.0, sigmaY: 25.0),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(borderRadius),
            gradient: LinearGradient(colors: [Colors.white.withOpacity(0.15), Colors.white.withOpacity(0.05)]),
            border: Border.all(color: Colors.white.withOpacity(0.25), width: 1.0),
          ),
          child: child,
        ),
      ),
    );
  }
}

// --- Player Screen ---
class ProVideoPlayerScreen extends StatefulWidget {
  final String videoPath;
  const ProVideoPlayerScreen({Key? key, required this.videoPath}) : super(key: key);

  @override
  State<ProVideoPlayerScreen> createState() => _ProVideoPlayerScreenState();
}

class _ProVideoPlayerScreenState extends State<ProVideoPlayerScreen> {
  late final Player player;
  late final VideoController controller;
  bool isPlaying = true;
  Duration currentPosition = Duration.zero;
  Duration totalDuration = Duration.zero;
  bool _areControlsVisible = true;
  Timer? _hideControlsTimer;
  bool _isSwiping = false;
  Duration _swipeSeekTo = Duration.zero;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);
    player = Player();
    controller = VideoController(player);
    player.open(Media(widget.videoPath));
    player.stream.playing.listen((playing) { if(mounted) setState(() { isPlaying = playing; }); });
    player.stream.position.listen((pos) { if(mounted) setState(() { currentPosition = pos; }); });
    player.stream.duration.listen((dur) { if(mounted) setState(() { totalDuration = dur; }); });
    _startHideControlsTimer();
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    player.dispose();
    _hideControlsTimer?.cancel();
    super.dispose();
  }

  void _togglePlay() {
    _showControls();
    isPlaying ? player.pause() : player.play();
  }

  void _seekRelative(int seconds) {
    _showControls();
    final newPos = currentPosition + Duration(seconds: seconds);
    if(newPos > Duration.zero && newPos < totalDuration) player.seek(newPos);
  }

  void _startHideControlsTimer() {
    _hideControlsTimer?.cancel();
    _hideControlsTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && isPlaying && !_isSwiping) setState(() { _areControlsVisible = false; });
    });
  }

  void _showControls() {
    setState(() { _areControlsVisible = true; });
    _startHideControlsTimer();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: () => _areControlsVisible ? setState(() => _areControlsVisible = false) : _showControls(),
        onHorizontalDragStart: (details) {
          _showControls();
          _hideControlsTimer?.cancel();
          _isSwiping = true;
          _swipeSeekTo = currentPosition;
        },
        onHorizontalDragUpdate: (details) {
          setState(() {
            _swipeSeekTo += Duration(milliseconds: (details.primaryDelta! * 500).toInt());
            if(_swipeSeekTo < Duration.zero) _swipeSeekTo = Duration.zero;
            if(_swipeSeekTo > totalDuration) _swipeSeekTo = totalDuration;
          });
        },
        onHorizontalDragEnd: (details) {
          player.seek(_swipeSeekTo);
          setState(() { _isSwiping = false; });
          _startHideControlsTimer();
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            InteractiveViewer(minScale: 1.0, maxScale: 3.0, child: Video(controller: controller, controls: NoVideoControls)),
            AnimatedOpacity(
              opacity: _areControlsVisible ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 300),
              child: IgnorePointer(
                ignoring: !_areControlsVisible,
                child: Stack(
                  children: [
                    Positioned(
                      top: 40, left: 20, right: 20,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          GestureDetector(onTap: () => Navigator.pop(context), child: const _GlassIcon(icon: CupertinoIcons.xmark)),
                          const PremiumGlass(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10), borderRadius: 20, child: Row(children: [Icon(CupertinoIcons.tv, color: Colors.white), SizedBox(width: 20), Icon(CupertinoIcons.share, color: Colors.white)])),
                        ],
                      ),
                    ),
                    Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          GestureDetector(onTap: () => _seekRelative(-15), child: const _GlassIcon(icon: CupertinoIcons.gobackward_15, size: 60)),
                          const SizedBox(width: 30),
                          GestureDetector(onTap: _togglePlay, child: _GlassIcon(icon: isPlaying ? CupertinoIcons.pause_fill : CupertinoIcons.play_fill, size: 90)),
                          const SizedBox(width: 30),
                          GestureDetector(onTap: () => _seekRelative(15), child: const _GlassIcon(icon: CupertinoIcons.goforward_15, size: 60)),
                        ],
                      ),
                    ),
                    Positioned(
                      bottom: 30, left: 20, right: 20,
                      child: PremiumGlass(
                        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5), borderRadius: 25,
                        child: Row(
                          children: [
                            Text(_printDur(currentPosition), style: const TextStyle(color: Colors.white, fontSize: 12)),
                            Expanded(
                              child: Slider(
                                value: totalDuration.inMilliseconds > 0 ? (currentPosition.inMilliseconds / totalDuration.inMilliseconds).clamp(0.0, 1.0) : 0,
                                activeColor: Colors.white, inactiveColor: Colors.white24,
                                onChanged: (v) { _showControls(); player.seek(totalDuration * v); },
                              ),
                            ),
                            Text(_printDur(totalDuration - currentPosition), style: const TextStyle(color: Colors.white, fontSize: 12)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_isSwiping)
              Center(child: PremiumGlass(padding: const EdgeInsets.all(20), borderRadius: 20, child: Text(_printDur(_swipeSeekTo), style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)))),
          ],
        ),
      ),
    );
  }

  String _printDur(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    return "${d.inHours > 0 ? '${twoDigits(d.inHours)}:' : ''}${twoDigits(d.inMinutes.remainder(60))}:${twoDigits(d.inSeconds.remainder(60))}";
  }
}

class _GlassIcon extends StatelessWidget {
  final IconData icon;
  final double size;
  const _GlassIcon({required this.icon, this.size = 50});
  @override
  Widget build(BuildContext context) {
    return PremiumGlass(borderRadius: size / 2, child: SizedBox(width: size, height: size, child: Icon(icon, color: Colors.white, size: size * 0.5)));
  }
}
