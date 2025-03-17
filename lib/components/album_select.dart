import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:pms/components/export.dart';
import 'package:pms/db/export.dart';
import 'package:pms/pages/export.dart';

// ignore: must_be_immutable
class AlbumSelectComp extends GetView<HomeController> {
  late bool isLocalPlatform = true;
  late List<String> excludes;
  late MediaTagType type;

  void Function(AlbumDbModel album) onSelect;

  AlbumSelectComp({
    super.key,
    required this.isLocalPlatform,
    required this.type,
    required this.onSelect,
    this.excludes = const [],
  });

  @override
  Widget build(BuildContext context) {
    var albums = (type == MediaTagType.video ? controller.videoAlbums : controller.musicAlbums).where((item) {
      if (isLocalPlatform) {
        return item.platform == MediaPlatformType.local && item.relationId != MediaPlatformType.local.name;
      }
      if (excludes.contains(item.relationId)) {
        return false;
      }
      return item.platform == MediaPlatformType.aliyun || item.relationId.contains('cloud');
    }).toList();

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 30.w, vertical: 20.w),
          child: Row(
            children: [
              Text(
                '添加到专辑'.tr,
                style: TextStyle(fontSize: 28.w),
              )
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.all(20.w).copyWith(top: 0),
            itemCount: albums.length,
            itemBuilder: (_, index) {
              var album = albums[index];
              return AlbumItemComp(
                album,
                onPress: () {
                  onSelect(album);
                },
              );
            },
          ),
        )
      ],
    );
  }
}
