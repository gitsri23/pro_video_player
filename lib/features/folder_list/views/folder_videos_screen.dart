import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

import 'package:pro_video_player/core/theme/premium_glass.dart';
import 'package:pro_video_player/features/video_player/views/pro_video_player.dart';

class FolderVideosScreen extends StatelessWidget {
  final String folderName;
  final List<File> videos;

  const FolderVideosScreen({Key? key, required this.folderName, required this.videos}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(folderName, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.black,
        leading: const BackButton(color: Colors.white),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: videos.length,
        itemBuilder: (context, index) {
          File video = videos[index];
          String fileName = p.basename(video.path);
          
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: PremiumGlass(
              borderRadius: 15,
              padding: const EdgeInsets.all(4),
              child: ListTile(
                leading: const Icon(Icons.play_circle_outline, color: Colors.white70, size: 35),
                title: Text(fileName, style: const TextStyle(color: Colors.white, fontSize: 15), maxLines: 2),
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(
                    builder: (_) => ProVideoPlayerScreen(videoPath: video.path),
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
