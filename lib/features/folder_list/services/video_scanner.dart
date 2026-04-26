import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';

class VideoScanner {
  static Future<Map<String, List<File>>> getVideosGroupedByFolder() async {
    Map<String, List<File>> groupedVideos = {};
    
    // 1. Android version batti exact permission adagali (Android 13+ uses .videos)
    final androidInfo = await DeviceInfoPlugin().androidInfo;
    if (androidInfo.version.sdkInt >= 33) {
      var status = await Permission.videos.request();
      if (!status.isGranted) return groupedVideos; // Permission ivvakapothe empty list
    } else {
      var status = await Permission.storage.request();
      if (!status.isGranted) return groupedVideos;
    }

    Directory root = Directory('/storage/emulated/0/'); 
    final videoExtensions = ['.mp4', '.mkv', '.avi', '.mov', '.flv'];

    if (!await root.exists()) return groupedVideos;

    try {
      // 2. CRITICAL FIX: Error vasthe ignore chesi next file ki vellela async list() vadanu
      await for (var entity in root.list(recursive: true, followLinks: false).handleError((e) {
        // System / locked folders deggara permission lekapothe ignore chesthundi
        return; 
      })) {
        if (entity is File) {
          String extension = p.extension(entity.path).toLowerCase();
          if (videoExtensions.contains(extension)) {
            String folderName = p.basename(entity.parent.path);
            
            if (!groupedVideos.containsKey(folderName)) {
              groupedVideos[folderName] = [];
            }
            groupedVideos[folderName]!.add(entity);
          }
        }
      }
    } catch (e) {
      print("Global Scan Error: $e");
    }
    
    return groupedVideos;
  }
}
