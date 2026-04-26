import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media_kit/media_kit.dart';
import 'package:path/path.dart' as p;

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

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, List<File>> _folders = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    _loadVideos();
  }

  Future<void> _loadVideos() async {
    final folders = await VideoScanner.getVideosGroupedByFolder();
    if (mounted) setState(() { _folders = folders; _isLoading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Local Videos'), backgroundColor: Colors.black),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator(color: Colors.white70))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _folders.length,
              itemBuilder: (context, index) {
                String folderName = _folders.keys.elementAt(index);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: PremiumGlass(
                    borderRadius: 20, padding: const EdgeInsets.all(12),
                    child: ListTile(
                      leading: const Icon(Icons.folder, color: Colors.white70, size: 40),
                      title: Text(folderName, style: const TextStyle(color: Colors.white, fontSize: 18)),
                      subtitle: Text('${_folders[folderName]!.length} videos', style: const TextStyle(color: Colors.white60)),
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => FolderVideosScreen(folderName: folderName, videos: _folders[folderName]!))),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class FolderVideosScreen extends StatelessWidget {
  final String folderName;
  final List<File> videos;
  const FolderVideosScreen({Key? key, required this.folderName, required this.videos}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(folderName), backgroundColor: Colors.black),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: videos.length,
        itemBuilder: (context, index) {
          File video = videos[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: PremiumGlass(
              borderRadius: 15, padding: const EdgeInsets.all(4),
              child: ListTile(
                leading: const Icon(Icons.play_circle_outline, color: Colors.white70, size: 35),
                title: Text(p.basename(video.path), style: const TextStyle(color: Colors.white, fontSize: 15), maxLines: 2),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProVideoPlayerScreen(videoPath: video.path))),
              ),
            ),
          );
        },
      ),
    );
  }
}
