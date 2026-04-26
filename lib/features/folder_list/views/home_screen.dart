import 'dart:io';
import 'package:flutter/material.dart';
import '../services/video_scanner.dart';
import '../../video_player/views/pro_video_player.dart';

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
    _loadVideos();
  }

  Future<void> _loadVideos() async {
    final folders = await VideoScanner.getVideosGroupedByFolder();
    setState(() {
      _folders = folders;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Local Videos'), backgroundColor: Colors.black),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : ListView.builder(
              itemCount: _folders.length,
              itemBuilder: (context, index) {
                String folderName = _folders.keys.elementAt(index);
                List<File> videos = _folders[folderName]!;
                
                return ListTile(
                  leading: const Icon(Icons.folder, color: Colors.white70, size: 40),
                  title: Text(folderName, style: const TextStyle(color: Colors.white)),
                  subtitle: Text('${videos.length} videos', style: const TextStyle(color: Colors.white54)),
                  onTap: () {
                    if(videos.isNotEmpty) {
                       Navigator.push(context, MaterialPageRoute(
                         builder: (_) => ProVideoPlayerScreen(videoPath: videos.first.path)
                       ));
                    }
                  },
                );
              },
            ),
    );
  }
}
