import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:installed_apps/installed_apps.dart';
import 'package:installed_apps/app_info.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'dart:math' as math;
import 'dart:ui';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    systemNavigationBarColor: Colors.transparent,
  ));
  runApp(const MaterialApp(
    home: IOSLauncher(),
    debugShowCheckedModeBanner: false,
  ));
}

class IOSLauncher extends StatefulWidget {
  const IOSLauncher({super.key});

  @override
  State<IOSLauncher> createState() => _IOSLauncherState();
}

class _IOSLauncherState extends State<IOSLauncher>
    with TickerProviderStateMixin {
  List<AppInfo> allApps = [];
  List<AppInfo> filteredApps = [];
  final TextEditingController searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();

  bool isEditingMode = false;
  bool isTintedMode = false;
  bool _isSearching = false;

  late AnimationController _wiggleController;
  late AnimationController _pageController;

  // Tint color — user customizable
  Color _tintColor = Colors.blueAccent;

  @override
  void initState() {
    super.initState();
    _loadApps();

    _wiggleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );

    _pageController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    )..forward();
  }

  Future<void> _loadApps() async {
    List<AppInfo> apps = await InstalledApps.getInstalledApps(true, true);
    apps.sort((a, b) => (a.name ?? '').compareTo(b.name ?? ''));
    setState(() {
      allApps = apps;
      filteredApps = apps;
    });
  }

  void _filterApps(String query) {
    setState(() {
      filteredApps = query.isEmpty
          ? allApps
          : allApps
              .where((app) =>
                  app.name!.toLowerCase().contains(query.toLowerCase()))
              .toList();
    });
  }

  void _uninstallApp(String packageName) {
    HapticFeedback.mediumImpact();
    AndroidIntent(
      action: 'android.intent.action.DELETE',
      data: 'package:$packageName',
    ).launch();
  }

  void _openDefaultLauncherSettings() {
    const AndroidIntent(action: 'android.settings.HOME_SETTINGS').launch();
  }

  void _exitEditMode() {
    if (isEditingMode) {
      HapticFeedback.lightImpact();
      setState(() => isEditingMode = false);
      _wiggleController.stop();
      _wiggleController.reset();
    }
  }

  void _showControlCenter() {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      barrierColor: Colors.black26,
      builder: (_) => _buildControlCenter(),
    );
  }

  @override
  void dispose() {
    _wiggleController.dispose();
    _pageController.dispose();
    searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  // ─── BUILD ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.black,
      resizeToAvoidBottomInset: false,
      body: GestureDetector(
        onTap: () {
          _exitEditMode();
          if (_searchFocus.hasFocus) {
            _searchFocus.unfocus();
            setState(() => _isSearching = false);
          }
        },
        onVerticalDragEnd: (details) {
          if (details.primaryVelocity! > 300) _showControlCenter();
        },
        child: Stack(
          children: [
            // ── Wallpaper ──
            Positioned.fill(
              child: Image.network(
                "https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?q=80&w=1000&auto=format&fit=crop",
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF1a1a2e), Color(0xFF16213e), Color(0xFF0f3460)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
              ),
            ),

            // ── Wallpaper blur overlay ──
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 0, sigmaY: 0),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withOpacity(0.08),
                        Colors.black.withOpacity(0.25),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ),
            ),

            // ── Main content ──
            SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  _buildSearchBar(),
                  const SizedBox(height: 4),
                  Expanded(
                    child: filteredApps.isEmpty
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: Colors.white60,
                              strokeWidth: 1.5,
                            ),
                          )
                        : GridView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                            physics: const BouncingScrollPhysics(),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 4,
                              mainAxisSpacing: 22,
                              crossAxisSpacing: 8,
                              childAspectRatio: 0.72,
                            ),
                            itemCount: filteredApps.length,
                            itemBuilder: (context, index) {
                              return _buildAppIcon(filteredApps[index], index);
                            },
                          ),
                  ),
                  _buildDock(),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── APP ICON ────────────────────────────────────────────────────────────

  Widget _buildAppIcon(AppInfo app, int index) {
    final double offset = (index % 2 == 0) ? 1.0 : -1.0;

    Widget iconImage() {
      if (app.icon != null) {
        return Image.memory(
          app.icon!,
          width: 60,
          height: 60,
          fit: BoxFit.cover,
          gaplessPlayback: true,
        );
      }
      return Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.grey.shade700, Colors.grey.shade900],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: const Icon(Icons.apps, color: Colors.white54, size: 28),
      );
    }

    Widget iconWithTint() {
      final raw = iconImage();
      if (!isTintedMode) return raw;
      return ColorFiltered(
        colorFilter:
            ColorFilter.mode(_tintColor.withOpacity(0.55), BlendMode.srcATop),
        child: raw,
      );
    }

    return GestureDetector(
      onTap: () {
        if (isEditingMode) {
          _exitEditMode();
          return;
        }
        HapticFeedback.lightImpact();
        InstalledApps.startApp(app.packageName!);
      },
      onLongPress: () {
        HapticFeedback.heavyImpact();
        setState(() => isEditingMode = true);
        _wiggleController.repeat(reverse: true);
      },
      child: AnimatedBuilder(
        animation: _wiggleController,
        builder: (context, child) {
          final angle = isEditingMode
              ? math.sin(_wiggleController.value * math.pi * 2) *
                  0.055 *
                  offset
              : 0.0;
          return Transform.rotate(angle: angle, child: child);
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Icon container ──
            Stack(
              clipBehavior: Clip.none,
              children: [
                // Main icon
                Container(
                  width: 62,
                  height: 62,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    // iOS-style subtle shadow
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.35),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                        spreadRadius: 0,
                      ),
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 3,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Stack(
                      children: [
                        iconWithTint(),
                        // iOS specular gloss highlight
                        Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            height: 28,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.white.withOpacity(0.22),
                                  Colors.white.withOpacity(0.0),
                                ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Delete badge ──
                if (isEditingMode)
                  Positioned(
                    top: -6,
                    left: -6,
                    child: GestureDetector(
                      onTap: () => _uninstallApp(app.packageName!),
                      child: Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.75),
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: Colors.white.withOpacity(0.8), width: 1.5),
                        ),
                        child: const Icon(Icons.remove,
                            size: 13, color: Colors.white),
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 5),

            // ── Label ──
            SizedBox(
              width: 72,
              child: Text(
                app.name ?? '',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                  letterSpacing: -0.1,
                  shadows: [
                    Shadow(
                        blurRadius: 4,
                        color: Colors.black87,
                        offset: Offset(0, 1)),
                    Shadow(blurRadius: 8, color: Colors.black54),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── SEARCH BAR ──────────────────────────────────────────────────────────

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: Colors.white.withOpacity(0.25), width: 0.8),
            ),
            child: TextField(
              controller: searchController,
              focusNode: _searchFocus,
              onChanged: _filterApps,
              onTap: () => setState(() => _isSearching = true),
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w400),
              decoration: InputDecoration(
                hintText: 'Search',
                hintStyle: TextStyle(
                    color: Colors.white.withOpacity(0.55),
                    fontSize: 15,
                    fontWeight: FontWeight.w400),
                prefixIcon: Icon(Icons.search,
                    color: Colors.white.withOpacity(0.6), size: 20),
                suffixIcon: _isSearching && searchController.text.isNotEmpty
                    ? GestureDetector(
                        onTap: () {
                          searchController.clear();
                          _filterApps('');
                          _searchFocus.unfocus();
                          setState(() => _isSearching = false);
                        },
                        child: Icon(Icons.cancel,
                            color: Colors.white.withOpacity(0.5), size: 18),
                      )
                    : null,
                border: InputBorder.none,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─── DOCK ─────────────────────────────────────────────────────────────────

  Widget _buildDock() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 10),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
          child: Container(
            height: 88,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(
                  color: Colors.white.withOpacity(0.28), width: 0.8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _dockIcon(Icons.phone_rounded, const Color(0xFF34C759),
                    () => InstalledApps.startApp('com.android.contacts')),
                _dockIcon(Icons.chat_bubble_rounded, const Color(0xFF007AFF),
                    () => InstalledApps.startApp('com.google.android.apps.messaging')),
                _dockIcon(Icons.photo_library_rounded, const Color(0xFFFF9500),
                    () => InstalledApps.startApp('com.google.android.apps.photos')),
                _dockIcon(Icons.public_rounded, const Color(0xFF007AFF),
                    () => InstalledApps.startApp('com.android.chrome')),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _dockIcon(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        width: 58,
        height: 58,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.4),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.25),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            Center(child: Icon(icon, color: Colors.white, size: 30)),
            // gloss
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
                child: Container(
                  height: 26,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withOpacity(0.2),
                        Colors.transparent,
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── CONTROL CENTER ───────────────────────────────────────────────────────

  Widget _buildControlCenter() {
    return StatefulBuilder(builder: (ctx, setModal) {
      return Container(
        height: MediaQuery.of(context).size.height * 0.58,
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(36),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                borderRadius: BorderRadius.circular(36),
                border:
                    Border.all(color: Colors.white.withOpacity(0.15), width: 0.8),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: Column(
                  children: [
                    // Handle
                    Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 18),

                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Control Centre',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 19,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.4,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ── Toggle row ──
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _ccToggle(Icons.wifi_rounded, 'Wi-Fi', Colors.blue, true),
                        _ccToggle(Icons.bluetooth_rounded, 'BT', Colors.blue, true),
                        _ccToggle(Icons.airplanemode_active_rounded, 'Airplane',
                            Colors.orange, false),
                        // Tint toggle
                        GestureDetector(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() => isTintedMode = !isTintedMode);
                            setModal(() {});
                            Navigator.pop(ctx);
                          },
                          child: _ccToggleWidget(
                            Icons.palette_rounded,
                            'Tint',
                            isTintedMode ? _tintColor : Colors.grey.shade700,
                            isTintedMode,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // ── Tint color picker (shows when tint on) ──
                    if (isTintedMode) ...[
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Tint Colour',
                          style: TextStyle(
                              color: Colors.white60,
                              fontSize: 12,
                              fontWeight: FontWeight.w500),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Colors.blueAccent,
                          Colors.redAccent,
                          Colors.greenAccent,
                          Colors.purpleAccent,
                          Colors.orangeAccent,
                          Colors.pinkAccent,
                        ].map((c) {
                          final selected = _tintColor == c;
                          return GestureDetector(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              setState(() => _tintColor = c);
                              setModal(() {});
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: c,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: selected
                                      ? Colors.white
                                      : Colors.transparent,
                                  width: 2.5,
                                ),
                                boxShadow: selected
                                    ? [
                                        BoxShadow(
                                            color: c.withOpacity(0.6),
                                            blurRadius: 10)
                                      ]
                                    : [],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),
                    ],

                    const SizedBox(height: 4),

                    // ── Brightness slider ──
                    _ccSlider(Icons.brightness_high_rounded, 'Brightness'),
                    const SizedBox(height: 12),

                    // ── Volume slider ──
                    _ccSlider(Icons.volume_up_rounded, 'Volume'),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    });
  }

  Widget _ccToggle(IconData icon, String label, Color color, bool active) {
    return _ccToggleWidget(icon, label, active ? color : Colors.grey.shade700, active);
  }

  Widget _ccToggleWidget(IconData icon, String label, Color color, bool active) {
    return Column(
      children: [
        Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            color: active ? color : Colors.white.withOpacity(0.12),
            borderRadius: BorderRadius.circular(18),
            boxShadow: active
                ? [BoxShadow(color: color.withOpacity(0.4), blurRadius: 12)]
                : [],
          ),
          child: Icon(icon,
              color: active ? Colors.white : Colors.white54, size: 28),
        ),
        const SizedBox(height: 5),
        Text(label,
            style: TextStyle(
                color: Colors.white.withOpacity(0.65),
                fontSize: 10,
                fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _ccSlider(IconData icon, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                color: Colors.white.withOpacity(0.55),
                fontSize: 11,
                fontWeight: FontWeight.w500)),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          height: 46,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.12),
            borderRadius: BorderRadius.circular(23),
            border:
                Border.all(color: Colors.white.withOpacity(0.1), width: 0.5),
          ),
          child: Row(
            children: [
              const SizedBox(width: 14),
              Icon(icon, color: Colors.white70, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Container(
                    margin: const EdgeInsets.only(right: 16),
                    height: 6,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      gradient: LinearGradient(
                        colors: [
                          Colors.white,
                          Colors.white.withOpacity(0.25),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
