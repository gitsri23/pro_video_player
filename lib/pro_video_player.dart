import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

import 'liquid_glass.dart'; // LiquidGlassButton + LiquidGlassPanel

// ─────────────────────────────────────────
//  Custom iOS Slider
// ─────────────────────────────────────────
class _IosSlider extends StatelessWidget {
  final double value;
  final ValueChanged<double> onChanged;
  const _IosSlider({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SliderTheme(
      data: SliderTheme.of(context).copyWith(
        trackHeight: 3.5,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
        activeTrackColor: Colors.white,
        inactiveTrackColor: Colors.white24,
        thumbColor: Colors.white,
        overlayColor: Colors.white12,
      ),
      child: Slider(value: value, onChanged: onChanged),
    );
  }
}

// ─────────────────────────────────────────
//  Seek Indicator (+10s / -10s)
// ─────────────────────────────────────────
class _SeekIndicator extends StatelessWidget {
  final bool forward;
  const _SeekIndicator({required this.forward});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xBB000000),
        borderRadius: BorderRadius.circular(40),
        border: Border.all(color: Colors.white.withOpacity(0.1), width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: forward
            ? [
                const Text("10s",
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 13)),
                const SizedBox(width: 6),
                const Icon(CupertinoIcons.forward_fill,
                    color: Colors.white, size: 16),
              ]
            : [
                const Icon(CupertinoIcons.backward_fill,
                    color: Colors.white, size: 16),
                const SizedBox(width: 6),
                const Text("10s",
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 13)),
              ],
      ),
    );
  }
}

// ─────────────────────────────────────────
//  Player Screen
// ─────────────────────────────────────────
class ProVideoPlayerScreen extends StatefulWidget {
  final String videoPath;
  const ProVideoPlayerScreen({Key? key, required this.videoPath})
      : super(key: key);

  @override
  State<ProVideoPlayerScreen> createState() => _ProVideoPlayerScreenState();
}

class _ProVideoPlayerScreenState extends State<ProVideoPlayerScreen>
    with SingleTickerProviderStateMixin {
  late final Player player;
  late final VideoController controller;

  bool isPlaying = true;
  Duration currentPosition = Duration.zero;
  Duration totalDuration = Duration.zero;
  bool _areControlsVisible = true;
  Timer? _hideControlsTimer;
  bool _showLeftSeek = false;
  bool _showRightSeek = false;

  late AnimationController _controlsAnim;
  late Animation<double> _controlsOpacity;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations(
        [DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    _controlsAnim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 220));
    _controlsOpacity =
        CurvedAnimation(parent: _controlsAnim, curve: Curves.easeInOut);
    _controlsAnim.forward();

    player = Player();
    controller = VideoController(player);
    player.open(Media(widget.videoPath));

    player.stream.playing
        .listen((v) { if (mounted) setState(() => isPlaying = v); });
    player.stream.position
        .listen((v) { if (mounted) setState(() => currentPosition = v); });
    player.stream.duration
        .listen((v) { if (mounted) setState(() => totalDuration = v); });

    _startHideTimer();
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _controlsAnim.dispose();
    _hideControlsTimer?.cancel();
    player.dispose();
    super.dispose();
  }

  void _startHideTimer() {
    _hideControlsTimer?.cancel();
    _hideControlsTimer = Timer(const Duration(seconds: 4), () {
      if (mounted && isPlaying) _hideControls();
    });
  }

  void _hideControls() {
    _controlsAnim.reverse().then((_) {
      if (mounted) setState(() => _areControlsVisible = false);
    });
  }

  void _showControls() {
    setState(() => _areControlsVisible = true);
    _controlsAnim.forward();
    _startHideTimer();
  }

  void _toggleControlsVisibility() =>
      _areControlsVisible ? _hideControls() : _showControls();

  void _togglePlay() {
    HapticFeedback.lightImpact();
    _showControls();
    isPlaying ? player.pause() : player.play();
  }

  void _seekRelative(int seconds) {
    final newPos = currentPosition + Duration(seconds: seconds);
    final clamped = newPos.isNegative
        ? Duration.zero
        : (newPos > totalDuration ? totalDuration : newPos);
    player.seek(clamped);
  }

  void _handleDoubleTap(bool isForward) {
    HapticFeedback.mediumImpact();
    _seekRelative(isForward ? 10 : -10);
    if (isForward) {
      setState(() => _showRightSeek = true);
      Future.delayed(const Duration(milliseconds: 600),
          () => mounted ? setState(() => _showRightSeek = false) : null);
    } else {
      setState(() => _showLeftSeek = true);
      Future.delayed(const Duration(milliseconds: 600),
          () => mounted ? setState(() => _showLeftSeek = false) : null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final double progress = totalDuration.inMilliseconds > 0
        ? (currentPosition.inMilliseconds / totalDuration.inMilliseconds)
            .clamp(0.0, 1.0)
        : 0.0;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── 1. Video ──────────────────────────────────────
          InteractiveViewer(
            minScale: 1.0,
            maxScale: 3.0,
            child: Video(controller: controller, controls: NoVideoControls),
          ),

          // ── 2. Tap / double-tap zones ─────────────────────
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: _toggleControlsVisibility,
                  onDoubleTap: () => _handleDoubleTap(false),
                  behavior: HitTestBehavior.opaque,
                  child: const SizedBox.expand(),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: _toggleControlsVisibility,
                  onDoubleTap: () => _handleDoubleTap(true),
                  behavior: HitTestBehavior.opaque,
                  child: const SizedBox.expand(),
                ),
              ),
            ],
          ),

          // ── 3. Seek indicators ────────────────────────────
          if (_showLeftSeek)
            Positioned(
              left: 48, top: 0, bottom: 0,
              child: Center(child: _SeekIndicator(forward: false)),
            ),
          if (_showRightSeek)
            Positioned(
              right: 48, top: 0, bottom: 0,
              child: Center(child: _SeekIndicator(forward: true)),
            ),

          // ── 4. Controls overlay ───────────────────────────
          if (_areControlsVisible)
            FadeTransition(
              opacity: _controlsOpacity,
              child: IgnorePointer(
                ignoring: !_areControlsVisible,
                child: Stack(
                  children: [
                    // Top scrim
                    Positioned(
                      top: 0, left: 0, right: 0, height: 110,
                      child: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Color(0xCC000000), Colors.transparent],
                          ),
                        ),
                      ),
                    ),
                    // Bottom scrim
                    Positioned(
                      bottom: 0, left: 0, right: 0, height: 130,
                      child: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [Color(0xCC000000), Colors.transparent],
                          ),
                        ),
                      ),
                    ),

                    // ── Top bar ────────────────────────────
                    Positioned(
                      top: 18, left: 16, right: 16,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Close
                          LiquidGlassButton(
                            icon: CupertinoIcons.xmark,
                            size: 38,
                            onTap: () {
                              HapticFeedback.selectionClick();
                              Navigator.pop(context);
                            },
                          ),
                          // AirPlay + Share
                          LiquidGlassPanel(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            radius: 22,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                LiquidGlassButton(
                                  icon: CupertinoIcons.tv,
                                  size: 34,
                                  onTap: () {},
                                ),
                                const SizedBox(width: 8),
                                LiquidGlassButton(
                                  icon: CupertinoIcons.share,
                                  size: 34,
                                  onTap: () {},
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ── Center controls ────────────────────
                    Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          LiquidGlassButton(
                            icon: CupertinoIcons.gobackward_15,
                            size: 58,
                            onTap: () {
                              HapticFeedback.selectionClick();
                              _showControls();
                              _seekRelative(-15);
                            },
                          ),
                          const SizedBox(width: 26),
                          LiquidGlassButton(
                            icon: isPlaying
                                ? CupertinoIcons.pause_fill
                                : CupertinoIcons.play_fill,
                            size: 80,
                            onTap: _togglePlay,
                          ),
                          const SizedBox(width: 26),
                          LiquidGlassButton(
                            icon: CupertinoIcons.goforward_15,
                            size: 58,
                            onTap: () {
                              HapticFeedback.selectionClick();
                              _showControls();
                              _seekRelative(15);
                            },
                          ),
                        ],
                      ),
                    ),

                    // ── Bottom seek bar ────────────────────
                    Positioned(
                      bottom: 20, left: 16, right: 16,
                      child: LiquidGlassPanel(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        radius: 18,
                        child: Row(
                          children: [
                            Text(
                              _printDur(currentPosition),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Expanded(
                              child: _IosSlider(
                                value: progress,
                                onChanged: (v) {
                                  _showControls();
                                  player.seek(totalDuration * v);
                                },
                              ),
                            ),
                            Text(
                              "-${_printDur(totalDuration - currentPosition)}",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
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
    String two(int n) => n.toString().padLeft(2, "0");
    return "${d.inHours > 0 ? '${two(d.inHours)}:' : ''}${two(d.inMinutes.remainder(60))}:${two(d.inSeconds.remainder(60))}";
  }
}
