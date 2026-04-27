import 'package:photo_manager/photo_manager.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';

class VideoScanner {
  static Future<List<AssetPathEntity>> getAlbums() async {
    bool isGranted = false;
    
    // 1. Android version batti exact permission aduguthundi (Pop-up guarantee)
    final androidInfo = await DeviceInfoPlugin().androidInfo;
    
    if (androidInfo.version.sdkInt >= 33) {
      // Android 13 and above
      final status = await Permission.videos.request();
      isGranted = status.isGranted;
    } else {
      // Android 12 and below
      final status = await Permission.storage.request();
      isGranted = status.isGranted;
    }

    // 2. Permission isthe, ventane videos load chesthundi
    if (isGranted) {
      return await PhotoManager.getAssetPathList(
        type: RequestType.video,
        filterOption: FilterOptionGroup(
          videoOption: const FilterOption(
            needTitle: true,
            sizeConstraint: SizeConstraint(ignoreSize: true),
          ),
        ),
      );
    } 
    
    // 3. Permission ivvakapothe empty list pampisthundi
    return [];
  }
}
