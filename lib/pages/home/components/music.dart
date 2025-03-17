import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:pms/apis/export.dart';
import 'package:pms/components/export.dart';
import 'package:pms/db/export.dart';
import 'package:pms/pages/export.dart';
import 'package:pms/utils/export.dart';

class MusicComp extends GetView<HomeController> {
  const MusicComp({super.key});

  Widget renderImportAblum() {
    return AlbumItemComp(
      AlbumDbModel.importAlbumAction,
      onPress: () {
        Tool.showBottomSheet(
          SizedBox(
            height: 800.w,
            child: UserOperation(
              type: MediaTagType.muisc,
              onSave: (list, user) async {
                EasyLoading.show(
                  status: '导入中...'.tr,
                  maskType: EasyLoadingMaskType.black,
                );

                try {
                  await user.updateToken();

                  for (var album in list) {
                    if (album.isAliyunPlatform) {
                      var sizeInfo =
                          await AliyunApi.getFolderSizeInfo(
                            fileId: album.relationId,
                            driveId: user.extra.driveId,
                            xDeviceId: user.extra.xDeviceId,
                            token: user.accessToken,
                            xSignature: user.extra.xSignature,
                          ).getData();

                      if (sizeInfo.fileCount > 0) {
                        var files =
                            await AliyunApi.search(
                              driveId: user.extra.driveId,
                              xDeviceId: user.extra.xDeviceId,
                              token: user.accessToken,
                              xSignature: user.extra.xSignature,
                              parentFileIds: [album.relationId],
                              categorys: ['audio', 'video'],
                            ).getData();
                        var cover = files.items.firstWhereOrNull(
                          (item) => item.thumbnail.isNotEmpty,
                        );
                        if (cover != null) {
                          album.cover = cover.thumbnail;
                        }
                        album.count = sizeInfo.fileCount;
                      }
                    }

                    if (album.isNeteasePlatform &&
                        album.relationId.contains('cloud')) {
                      var response =
                          await NeteaseApi.getCloudSong(
                            cookie: user.accessToken,
                          ).getData();
                      album.count = response.count;
                    }

                    if (album.cover.startsWith('http')) {
                      var file = await Tool.cacheImg(
                        url: album.cover,
                        referer: user.extra.referer,
                      );
                      var coverpath = await Tool.getCoverStorePath();
                      var name = file.path.split('/').last;
                      await file.copy('$coverpath/$name');
                      album.cover = '$coverpath/$name';
                    }

                    await AlbumDbModel.insert(album);
                  }

                  await controller.initMuiceAlbums();
                  EasyLoading.dismiss();
                } catch (e) {
                  EasyLoading.dismiss();
                  EasyLoading.showToast(e.toString());
                }
              },
            ),
          ),
        );
      },
    );
  }

  Widget renderCreateAlbum() {
    return AlbumItemComp(
      AlbumDbModel.createAlbumAction,
      onPress: () {
        Tool.showBottomSheet(
          AlbumOperationComp(
            onSave: (value) async {
              var model = AlbumDbModel(
                name: value,
                type: MediaTagType.muisc,
                platform: MediaPlatformType.local,
                isSelf: 1,
              );
              var id = await AlbumDbModel.insert(model);
              model.id = id;
              controller.musicAlbums.add(model);
              Get.back();
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Obx(() {
          var albums = controller.musicAlbums;

          return ListView.builder(
            padding: EdgeInsets.all(18.w).copyWith(bottom: 140.w),
            itemCount: albums.length + 2,
            itemBuilder: (_, index) {
              if (index == albums.length + 1) {
                return renderImportAblum();
              }
              if (index == albums.length) {
                return renderCreateAlbum();
              }

              var album = albums[index];

              var disable = album.relationId.contains('local');

              return AlbumItemComp(
                album,
                onDelete:
                    disable
                        ? null
                        : () async {
                          await album.remove();
                          albums.remove(album);
                        },
                onPress: () async {
                  await MusicAlbumPage.to(albums[index]);
                  controller.initMuiceAlbums();
                },
              );
            },
          );
        }),
        const Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: SongBottomBarComp(),
        ),
      ],
    );
  }
}
