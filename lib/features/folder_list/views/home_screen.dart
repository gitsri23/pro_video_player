import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:pro_video_player/core/theme/premium_glass.dart';
import 'package:pro_video_player/features/folder_list/services/video_scanner.dart';
import 'package:pro_video_player/features/folder_list/views/folder_videos_screen.dart';

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
    if (mounted) {
      setState(() {
        _folders = folders;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Local Videos', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white70))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _folders.length,
              itemBuilder: (context, index) {
                String folderName = _folders.keys.elementAt(index);
                int count = _folders[folderName]!.length;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: PremiumGlass(
                    borderRadius: 20,
                    padding: const EdgeInsets.all(12),
                    child: ListTile(
                      leading: const Icon(Icons.folder, color: Colors.white70, size: 40),
                      title: Text(folderName, style: const TextStyle(color: Colors.white, fontSize: 18)),
                      subtitle: Text('$count videos', style: const TextStyle(color: Colors.white60)),
                      trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white30, size: 16),
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(
                          builder: (_) => FolderVideosScreen(
                            folderName: folderName,
                            videos: _folders[folderName]!,
                          ),
                        ));
                      },
                    ),
                  ),
                );
              },
            ),
    );
  }
}
