import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media_kit/media_kit.dart';
import 'package:photo_manager/photo_manager.dart';

import 'video_scanner.dart';
import 'pro_video_player.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pro Video Player',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(scaffoldBackgroundColor: Colors.black),
      home: const HomeScreen(),
    );
  }
}

// --- Solid iOS-style card (NO BackdropFilter, NO blur) ---
class PremiumGlass extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;

  const PremiumGlass({
    Key? key,
    required this.child,
    this.borderRadius = 30.0,
    this.padding,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E), // iOS system grouped background
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: Colors.white.withOpacity(0.08), width: 0.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }
}

// --- Home Screen ---
class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<AssetPathEntity> _albums = [];
  bool _isLoading = true;
  final PageController _pageController = PageController(viewportFraction: 0.75);

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    _loadAlbums();
  }

  Future<void> _loadAlbums() async {
    final albums = await VideoScanner.getAlbums();
    if (mounted) setState(() { _albums = albums; _isLoading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Local Folders', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white70))
          : _albums.isEmpty
              ? const Center(child: Text("No Videos Found", style: TextStyle(color: Colors.white)))
              : Center(
                  child: SizedBox(
                    height: 400,
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: _albums.length,
                      itemBuilder: (context, index) {
                        return AnimatedBuilder(
                          animation: _pageController,
                          builder: (context, child) {
                            double value = 1.0;
                            if (_pageController.position.haveDimensions) {
                              value = _pageController.page! - index;
                              value = (1 - (value.abs() * 0.25)).clamp(0.0, 1.0);
                            }
                            return Transform.scale(
                              scale: Curves.easeOut.transform(value),
                              child: child,
                            );
                          },
                          child: GestureDetector(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => FolderVideosScreen(album: _albums[index]),
                              ),
                            ),
                            child: PremiumGlass(
                              borderRadius: 30,
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.folder_special, color: Colors.white70, size: 80),
                                  const SizedBox(height: 20),
                                  Text(
                                    _albums[index].name,
                                    style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                  ),
                                  const SizedBox(height: 10),
                                  FutureBuilder<int>(
                                    future: _albums[index].assetCountAsync,
                                    builder: (_, snapshot) => Text(
                                      '${snapshot.data ?? 0} Videos',
                                      style: const TextStyle(color: Colors.white54, fontSize: 18),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
    );
  }
}

// --- Folder Videos Screen ---
class FolderVideosScreen extends StatefulWidget {
  final AssetPathEntity album;
  const FolderVideosScreen({Key? key, required this.album}) : super(key: key);

  @override
  State<FolderVideosScreen> createState() => _FolderVideosScreenState();
}

class _FolderVideosScreenState extends State<FolderVideosScreen> {
  List<AssetEntity> _videos = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchVideos();
  }

  Future<void> _fetchVideos() async {
    final int count = await widget.album.assetCountAsync;
    final List<AssetEntity> videos =
        await widget.album.getAssetListRange(start: 0, end: count);
    if (mounted) setState(() { _videos = videos; _isLoading = false; });
  }

  void _playVideo(AssetEntity video) async {
    final File? file = await video.file;
    if (file != null && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ProVideoPlayerScreen(videoPath: file.path)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.album.name), backgroundColor: Colors.black),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _videos.length,
              itemBuilder: (context, index) {
                final video = _videos[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: PremiumGlass(
                    borderRadius: 15,
                    padding: const EdgeInsets.all(8),
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: SizedBox(
                          width: 80,
                          height: 60,
                          child: FutureBuilder<Uint8List?>(
                            future: video.thumbnailDataWithSize(const ThumbnailSize(200, 200)),
                            builder: (_, snapshot) {
                              if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
                                return Image.memory(snapshot.data!, fit: BoxFit.cover);
                              }
                              return Container(
                                color: Colors.white10,
                                child: const Icon(Icons.video_file, color: Colors.white30),
                              );
                            },
                          ),
                        ),
                      ),
                      title: Text(
                        video.title ?? 'Unknown Video',
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        '${(video.duration / 60).floor()}:${(video.duration % 60).toString().padLeft(2, '0')}',
                        style: const TextStyle(color: Colors.white54, fontSize: 12),
                      ),
                      trailing: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 30),
                      onTap: () => _playVideo(video),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
