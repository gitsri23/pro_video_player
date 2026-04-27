import 'dart:async';
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For Haptics
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
  
  // Double Tap Animations
  bool _showLeftDoubleTap = false;
  bool _showRightDoubleTap = false;

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
    HapticFeedback.lightImpact(); // iOS Taptic Feel
    _showControls();
    isPlaying ? player.pause() : player.play();
  }

  void _seekRelative(int seconds) {
    HapticFeedback.selectionClick(); // iOS Taptic Feel
    _showControls();
    final newPos = currentPosition + Duration(seconds: seconds);
    if(newPos > Duration.zero && newPos < totalDuration) player.seek(newPos);
  }

  // Double Tap Logic
  void _handleDoubleTap(bool isForward) {
    HapticFeedback.mediumImpact();
    if (isForward) {
      _seekRelative(10);
      setState(() => _showRightDoubleTap = true);
      Future.delayed(const Duration(milliseconds: 500), () => setState(() => _showRightDoubleTap = false));
    } else {
      _seekRelative(-10);
      setState(() => _showLeftDoubleTap = true);
      Future.delayed(const Duration(milliseconds: 500), () => setState(() => _showLeftDoubleTap = false));
    }
  }

  void _startHideControlsTimer() {
    _hideControlsTimer?.cancel();
    _hideControlsTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && isPlaying) setState(() { _areControlsVisible = false; });
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
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Video Layer
          InteractiveViewer(minScale: 1.0, maxScale: 3.0, child: Video(controller: controller, controls: NoVideoControls)),
          
          // 2. Invisible Gesture Detectors for Double Tap
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => _areControlsVisible ? setState(() => _areControlsVisible = false) : _showControls(),
                  onDoubleTap: () => _handleDoubleTap(false), // Backward 10s
                  child: Container(color: Colors.transparent),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => _areControlsVisible ? setState(() => _areControlsVisible = false) : _showControls(),
                  onDoubleTap: () => _handleDoubleTap(true), // Forward 10s
                  child: Container(color: Colors.transparent),
                ),
              ),
            ],
          ),

          // 3. Double Tap Ripple Animations
          if (_showLeftDoubleTap)
            Positioned(left: 50, top: 0, bottom: 0, child: Center(child: PremiumGlass(padding: const EdgeInsets.all(15), borderRadius: 50, child: const Row(mainAxisSize: MainAxisSize.min, children: [Icon(CupertinoIcons.backward_fill, color: Colors.white), SizedBox(width: 5), Text("10s", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))])))),
          if (_showRightDoubleTap)
            Positioned(right: 50, top: 0, bottom: 0, child: Center(child: PremiumGlass(padding: const EdgeInsets.all(15), borderRadius: 50, child: const Row(mainAxisSize: MainAxisSize.min, children: [Text("10s", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), SizedBox(width: 5), Icon(CupertinoIcons.forward_fill, color: Colors.white)])))),

          // 4. Controls Layer
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
                        GestureDetector(onTap: () { HapticFeedback.selectionClick(); Navigator.pop(context); }, child: const _GlassIcon(icon: CupertinoIcons.xmark)),
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
        ],
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
