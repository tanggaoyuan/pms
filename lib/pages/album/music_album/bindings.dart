import 'dart:async';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:pms/apis/export.dart';
import 'package:pms/bindings/export.dart';
import 'package:pms/components/export.dart';
import 'package:pms/db/export.dart';
import 'package:pms/utils/export.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

enum MusicCheckType { download, delete, addAlbum, upload, none }

class MusicModelController extends GetxController {
  var audioController = Get.find<AudioController>();

  RxList<MediaDbModel> songs = RxList<MediaDbModel>();
  var checkType = MusicCheckType.none.obs;
  var checkMaps = <String, MediaDbModel>{}.obs;

  late RefreshController refreshController;

  final _album = (Get.arguments as AlbumDbModel).obs;
  late UserDbModel user = UserDbModel(
    relationId: 'local',
    name: 'local',
    platform: MediaPlatformType.local,
  );
  final Map<String, MediaDbModel> _downloads = {};
  late Map<String, dynamic> _pageInfo = {
    'nextMarker': 'init',
    'page': 0,
    'hasMore': true,
  };

  void _init() async {
    try {
      EasyLoading.show(
        status: '加载中...'.tr,
        maskType: EasyLoadingMaskType.black,
      );
      if (!album.isLocalPlatform) {
        var users = await UserDbModel.findByRelationIds([
          album.relationUserId,
        ], album.platform);
        user = users.first;
        await user.updateToken();
      }
      await refreshList(false);
      EasyLoading.dismiss();
    } catch (e) {
      EasyLoading.dismiss();
      EasyLoading.showToast('获取数据异常'.tr);
    }
  }

  Future<void> refreshList([bool? clean = true]) async {
    _pageInfo = {'nextMarker': 'init', 'page': 0, 'hasMore': true};

    // refreshController.loadComplete();

    if (clean == true) {
      var tag = '';
      if (album.isAliyunPlatform) {
        tag = 'https://api.aliyundrive.com/adrive/v3/file/search';
      }
      if (album.isBiliPlatform) {
        if (album.isSelf == 1) {
          tag = 'https://api.bilibili.com/x/v3/fav/resource/list';
        } else {
          tag = 'https://api.bilibili.com/x/space/fav/season/list';
        }
      }
      if (album.isNeteasePlatform) {
        if (album.relationId.contains('cloud')) {
          tag = 'https://music.163.com/eapi/v1/cloud/get';
        } else {
          tag = 'https://music.163.com/eapi/v6/playlist/detail';
        }
      }
      await DioChainCache.deleteLocalCache(tag);
    }

    var list = await MediaDbModel.findByRelationAlbumId(
      ids: [album.relationId],
      platform: album.platform,
      type: MediaTagType.muisc,
    );

    for (var item in list) {
      _downloads[item.relationId] = item;
    }

    if (album.isAliyunPlatform) {
      var fileSize =
          await AliyunApi.getFolderSizeInfo(
            fileId: album.relationId,
            driveId: user.extra.driveId,
            xDeviceId: user.extra.xDeviceId,
            token: user.accessToken,
            xSignature: user.extra.xSignature,
          ).getData();
      if (album.count != fileSize.fileCount) {
        album.count = fileSize.fileCount;
        await album.update();
      }
    }

    return loadMoreList();
  }

  Future<void> loadMoreList() async {
    String nextMarker = _pageInfo['nextMarker'];
    bool hasMore = _pageInfo['hasMore'];
    int page = _pageInfo['page'];

    var cacheTime = const Duration(hours: 1).inMilliseconds.toDouble();

    if (album.songIds.isNotEmpty) {
      var [ab] = await AlbumDbModel.findByIds([album.id]);
      _album.value = ab;
      songs.value = await MediaDbModel.findByIds(ab.songIds);
      refreshController.refreshCompleted();
      refreshController.loadNoData();
      return;
    }

    if (album.isAliyunPlatform && nextMarker.isNotEmpty) {
      await user.updateToken();
      var response =
          await AliyunApi.search(
            driveId: user.extra.driveId,
            xDeviceId: user.extra.xDeviceId,
            token: user.accessToken,
            xSignature: user.extra.xSignature,
            parentFileIds: [album.relationId],
            categorys: ["audio"],
            limit: 50,
            marker:
                (nextMarker.isEmpty || nextMarker == 'init')
                    ? null
                    : nextMarker,
          ).setLocalCache(cacheTime).getData();

      List<MediaDbModel> items = [];

      List<Future<File>> tasks = [];

      for (var item in response.items) {
        var song = MediaDbModel.fromAliFile(
          album: album,
          user: user,
          file: item,
          type: MediaTagType.muisc,
        );
        items.add(_downloads[item.fileId] ?? song);
        if (song.cover.startsWith('http')) {
          tasks.add(
            Tool.cacheImg(
              url: song.cover,
              // cacheKey: '${MediaPlatformType.aliyun}@${item.fileId}',
              cacheKey: song.cacheKey,
              referer: song.extra.referer,
            ),
          );
        }
      }

      await Future.wait(tasks);

      if (nextMarker == 'init') {
        songs.value = items;
      } else {
        songs.addAll(items);
      }

      if (nextMarker == 'init') {
        refreshController.refreshCompleted();
      } else {
        refreshController.loadComplete();
      }

      _pageInfo['nextMarker'] = response.nextMarker;

      if (response.nextMarker.isEmpty) {
        refreshController.loadNoData();
      }
      return;
    } else if (album.isBiliPlatform && hasMore) {
      var promise =
          album.isSelf == 1
              ? BiliApi.getFavVideos(
                mediaId: album.relationId,
                cookie: user.accessToken,
                limit: 40,
                page: page + 1,
              )
              : BiliApi.getSubVideos(
                seasonId: album.relationId,
                cookie: user.accessToken,
                limit: 40,
                page: page + 1,
              );

      var response = await promise.setLocalCache(cacheTime).getData();

      var items =
          response.medias
              .where((item) => !item.isExpire)
              .map(
                (item) =>
                    _downloads[item.bvid] ??
                    MediaDbModel.fromBili(
                      album: album,
                      user: user,
                      file: item,
                      type: MediaTagType.muisc,
                    ),
              )
              .toList();
      if (page == 0) {
        songs.value = items;
      } else {
        songs.addAll(items);
      }
      _pageInfo['page'] = page + 1;
      _pageInfo['hasMore'] = response.hasMore;
      if (album.count != response.total) {
        album.count = response.total;
        await album.update();
      }
      refreshController.refreshCompleted();
      if (hasMore) {
        refreshController.loadComplete();
      } else {
        refreshController.loadNoData();
      }
    } else if (album.isNeteasePlatform && hasMore) {
      if (album.relationId.contains('cloud')) {
        var response =
            await NeteaseApi.getCloudSong(
              cookie: user.accessToken,
              limit: 10000,
            ).setLocalCache(cacheTime).getData();
        songs.value =
            response.songs.map((item) {
              return _downloads[item.id.toString()] ??
                  MediaDbModel.fromNetSong(
                    album: album,
                    user: user,
                    file: item,
                    type: MediaTagType.muisc,
                  );
            }).toList();
      } else {
        var list =
            await NeteaseApi.getAlbumSongs(
              id: album.relationId,
              cookie: user.accessToken,
              limit: 10000,
            ).setLocalCache(cacheTime).getData();
        songs.value =
            list.map((item) {
              return _downloads[item.id.toString()] ??
                  MediaDbModel.fromNetSong(
                    album: album,
                    user: user,
                    file: item,
                    type: MediaTagType.muisc,
                  );
            }).toList();
      }

      hasMore = false;
      album.count = songs.length;
      await album.update();
      refreshController.refreshCompleted();
      refreshController.loadNoData();
    } else {
      refreshController.loadNoData();
    }
  }

  Future<void> loadAllList() async {
    if (album.isAliyunPlatform) {
      while (_pageInfo['nextMarker'].isNotEmpty) {
        await loadMoreList();
      }
    }
    if (album.isBiliPlatform) {
      while (_pageInfo['hasMore']) {
        await loadMoreList();
      }
    }
  }

  Future<void> handleRemove(List<MediaDbModel> songs) async {
    try {
      EasyLoading.show(
        status: '${"正在删除".tr}...',
        maskType: EasyLoadingMaskType.black,
      );
      if (album.isLocalPlatform &&
          album.relationId == MediaPlatformType.local.name) {
        for (var song in songs) {
          await Tool.deleteAsset(song.local);
          song.local = '';
          await song.update();
        }
      }

      if (album.isAliyunPlatform) {
        await user.updateToken();
        await AliyunApi.deleteFile(
          fileIds: songs.map((item) => item.relationId).toList(),
          driveId: user.extra.driveId,
          xDeviceId: user.extra.xDeviceId,
          token: user.accessToken,
          xSignature: user.extra.xSignature,
        ).getData();
      }

      if (album.isNeteasePlatform) {
        await user.updateToken();
        if (album.relationId.contains('cloud')) {
          await NeteaseApi.deleteCloudSong(
            cookie: user.accessToken,
            tracks: songs.map((item) => item.relationId).toList(),
          );
        } else {
          await NeteaseApi.deleteSong(
            albumId: album.relationId,
            tracks: songs.map((item) => item.relationId).toList(),
            cookie: user.accessToken,
          );
        }
      }

      if (album.isBiliPlatform) {
        await user.updateToken();
        await BiliApi.deleteFavVideo(
          cookie: user.accessToken,
          mediaId: album.relationId,
          resources: songs.map((item) => item.extra.resourceId).toList(),
        );
      }

      for (var song in songs) {
        this.songs.remove(song);
        var num = album.songIds.indexOf(song.id);
        album.count--;
        if (num != -1) {
          album.songIds.removeAt(num);
        }
        await album.update();
      }
      EasyLoading.dismiss();
      EasyLoading.showToast('删除成功'.tr);
    } catch (e) {
      EasyLoading.dismiss();
      EasyLoading.showToast('删除任务失败'.tr);
    }
  }

  Future<void> handleAddAlbum(List<MediaDbModel> songs) async {
    var completer = Completer();
    Tool.showBottomSheet(
      SizedBox(
        height: 800.w,
        child: AlbumSelectComp(
          isLocalPlatform: true,
          type: MediaTagType.muisc,
          excludes: [album.relationId],
          onSelect: (album) async {
            try {
              EasyLoading.show(
                status: '${"添加中".tr}...',
                maskType: EasyLoadingMaskType.black,
              );
              List<int> ids = [...album.songIds];
              MediaDbModel? first;
              for (var media in songs) {
                if (media.id == -1) {
                  var id = await MediaDbModel.insert(media);
                  media.id = id;
                }
                var index = ids.indexOf(media.id);
                if (index == -1) {
                  ids.insert(0, media.id);
                  first = media;
                }
              }
              if (first != null) {
                album.cover = first.cover;
              }
              album.songIds = ids;
              await album.update();
              Get.back();
              EasyLoading.dismiss();
              EasyLoading.showToast('已添加'.tr);
              completer.complete(true);
            } catch (e) {
              EasyLoading.dismiss();
              EasyLoading.showToast('添加失败'.tr);
              completer.completeError(e);
            }
          },
        ),
      ),
    );

    return completer.future;
  }

  Future<void> handleDownload(List<MediaDbModel> songs) async {
    try {
      EasyLoading.show(
        status: '${"添加下载任务中".tr}...',
        maskType: EasyLoadingMaskType.black,
      );
      var taskController = Get.find<TaskController>();
      for (var media in songs) {
        if (media.id == -1) {
          var id = await MediaDbModel.insert(media);
          media.id = id;
        }
        taskController.createTask(
          media: media,
          taskType: MediaTaskType.download,
          remark: '本地音乐'.tr,
        );
      }
      EasyLoading.dismiss();
      EasyLoading.showToast('已添加下载任务'.tr);
    } catch (e) {
      EasyLoading.dismiss();
      EasyLoading.showToast('添加下载任务失败'.tr);
    }
  }

  Future<void> handleUpload(List<MediaDbModel> songs) async {
    var completer = Completer();

    Tool.showBottomSheet(
      SizedBox(
        height: 800.w,
        child: AlbumSelectComp(
          isLocalPlatform: false,
          type: MediaTagType.muisc,
          excludes: [album.relationId],
          onSelect: (album) async {
            try {
              EasyLoading.show(
                status: '生成上传任务中...'.tr,
                maskType: EasyLoadingMaskType.black,
              );
              List<MediaDbModel> temps = [];

              var [user] = await UserDbModel.findByRelationIds([
                album.relationUserId,
              ], album.platform);
              await user.updateToken();

              if (album.isNeteasePlatform) {
                var response =
                    await NeteaseApi.getCloudSong(
                      cookie: user.accessToken,
                      limit: 10000,
                    ).getData();
                temps =
                    response.songs.map((item) {
                      return MediaDbModel.fromNetSong(
                        album: album,
                        user: user,
                        file: item,
                        type: MediaTagType.muisc,
                      );
                    }).toList();
              }

              if (album.isAliyunPlatform) {
                var next = 'init';
                List<AliFile> items = [];
                while (next.isNotEmpty) {
                  var response =
                      await AliyunApi.search(
                        driveId: user.extra.driveId,
                        xDeviceId: user.extra.xDeviceId,
                        token: user.accessToken,
                        xSignature: user.extra.xSignature,
                        parentFileIds: [album.relationId],
                        fileIds: songs.map((item) => item.relationId).toList(),
                        limit: 100,
                        marker: next == 'init' ? null : next,
                      ).getData();

                  next = response.nextMarker;
                  items.addAll(response.items);
                }
                temps =
                    items.map((item) {
                      return MediaDbModel.fromAliFile(
                        album: album,
                        user: user,
                        file: item,
                        type: MediaTagType.muisc,
                      );
                    }).toList();
              }

              var keys = temps.map((item) => item.relationId).toList();

              for (var item in songs) {
                // 如果上传的是网易 歌曲是视频则跳过
                if (keys.contains(item.relationId) ||
                    (album.isNeteasePlatform &&
                        item.mimeType.contains('video'))) {
                  continue;
                }
                var controller = Get.find<TaskController>();
                await controller.createTask(
                  media: item,
                  taskType: MediaTaskType.upload,
                  uploadAlbumId: album.id,
                  remark: album.name,
                );
              }
              EasyLoading.dismiss();
              EasyLoading.showToast('任务已添加'.tr);
              Get.back();
              completer.complete(true);
            } catch (e) {
              EasyLoading.dismiss();
              EasyLoading.showToast('任务失败'.tr);
              completer.completeError(e);
            }
          },
        ),
      ),
    );

    return completer.future;
  }

  Future<void> checkAll() async {
    try {
      EasyLoading.show(
        status: '${"加载中".tr}...',
        maskType: EasyLoadingMaskType.black,
      );
      await loadAllList();
      for (var item in songs) {
        if (checkType.value == MusicCheckType.download) {
          if (item.local.isEmpty) {
            checkMaps[item.relationId] = item;
          }
        } else if (checkType.value == MusicCheckType.upload) {
          if (item.local.isNotEmpty) {
            checkMaps[item.relationId] = item;
          }
        } else {
          checkMaps[item.relationId] = item;
        }
      }
      EasyLoading.dismiss();
    } catch (e) {
      EasyLoading.dismiss();
      EasyLoading.showToast('获取数据异常'.tr);
    }
  }

  Future<void> confirmCheck() async {
    var list = checkMaps.values.toList();
    if (checkType.value == MusicCheckType.addAlbum) {
      await handleAddAlbum(list);
    }

    if (checkType.value == MusicCheckType.download) {
      await handleDownload(list);
    }

    if (checkType.value == MusicCheckType.delete) {
      await handleRemove(list);
    }

    if (checkType.value == MusicCheckType.upload) {
      await handleUpload(list);
    }

    checkMaps.clear();
    checkType.value = MusicCheckType.none;
  }

  Future<void> playAlbum(int index) async {
    // if (checkType.value != MusicCheckType.none) {
    //   return;
    // }
    try {
      EasyLoading.show(
        status: '${'加载中'.tr}...',
        maskType: EasyLoadingMaskType.black,
      );
      await loadAllList();
      audioController.setPlayList(songs);
      audioController.play(index, album.id);
      EasyLoading.dismiss();
    } catch (e) {
      EasyLoading.dismiss();
      EasyLoading.showToast('获取播放数据异常'.tr);
    }
  }

  get player {
    return audioController.player;
  }

  MediaDbModel get header {
    var header = MediaDbModel(
      name: "暂无数据".tr,
      platform: album.platform,
      type: MediaTagType.muisc,
    );
    if (isAlbumPlaying) {
      header = audioController.currentSong!;
    } else if (songs.isNotEmpty) {
      header = songs.first;
    }
    if (header.cover.isEmpty) {
      header.cover = ImgCompIcons.mainCover;
    }
    return header;
  }

  /// 当前播放歌曲是否为该专辑
  bool get isAlbumPlaying {
    return audioController.currentSong != null &&
        audioController.albumId.value == album.id;
  }

  /// 当前歌曲是否正在播放
  bool get isMusicPlaying {
    return isAlbumPlaying && audioController.playing.value;
  }

  AlbumDbModel get album {
    return _album.value;
  }

  @override
  void onInit() {
    super.onInit();
    refreshController = RefreshController();
    _init();
  }

  @override
  void onClose() {
    super.onClose();
    refreshController.dispose();
  }
}

class MusicModelBinding implements Bindings {
  @override
  void dependencies() {
    Get.lazyPut<MusicModelController>(() => MusicModelController());
  }
}
