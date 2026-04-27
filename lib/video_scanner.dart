import 'package:photo_manager/photo_manager.dart';

class VideoScanner {
  // Returns a list of video albums (folders) instantly
  static Future<List<AssetPathEntity>> getAlbums() async {
    final PermissionState ps = await PhotoManager.requestPermissionExtend();
    
    if (ps.isAuth || ps.hasAccess) {
      // Fetch only folders that contain videos
      List<AssetPathEntity> albums = await PhotoManager.getAssetPathList(
        type: RequestType.video,
        filterOption: FilterOptionGroup(
          videoOption: const FilterOption(
            needTitle: true,
            sizeConstraint: SizeConstraint(ignoreSize: true),
          ),
        ),
      );
      return albums;
    } else {
      PhotoManager.openSetting();
      return [];
    }
  }
}
