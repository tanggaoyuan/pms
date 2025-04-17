import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:pms/apis/export.dart';
import 'package:pms/bindings/export.dart';
import 'package:pms/components/export.dart';
import 'package:pms/db/export.dart';
import 'package:pms/utils/export.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:media_player_plugin/export.dart';

enum VideoCheckType { download, delete, addAlbum, upload, none }

class VideoModelController extends GetxController {
  final MediaVideoPlayer player = MediaVideoPlayer();
  late RefreshController refreshController = RefreshController();

  RxList<MediaDbModel> videos = RxList<MediaDbModel>();

  var checkType = VideoCheckType.none.obs;
  var checkMaps = <String, MediaDbModel>{}.obs;
  var playIndex = (-1).obs;

  final _isPlaying = false.obs;
  final _isPlayCompleted = false.obs;
  final _isBuffering = false.obs;
  final _duration = Duration.zero.obs;
  final _position = Duration.zero.obs;
  final _videoControlFlag = false.obs;
  final _buffered = Duration.zero.obs;
  final _videoMode = 0.obs;
  final _videoPlayMode = 0.obs;
  final _album = (Get.arguments as AlbumDbModel).obs;

  MediaDbModel get header {
    return videos.isEmpty
        ? MediaDbModel(
            name: "数据加载中".tr,
            platform: album.platform,
            type: MediaTagType.video,
          )
        : videos[playIndex.value < 0 ? 0 : playIndex.value];
  }

  bool get isPlaying => _isPlaying.value;

  Duration get position => _position.value;

  Duration get buffered => _buffered.value;

  Duration get duration => _duration.value;

  bool get isVertical => _videoMode.value == 1;
  bool get isHorizontal => _videoMode.value == 2;
  bool get isNone => _videoMode.value == 0;

  int get playMode => _videoPlayMode.value;

  bool get videoControlFlag => _videoControlFlag.value;

  AlbumDbModel get album => _album.value;

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

  Timer? _videoControlTimer;

  _initPlayer() async {
    await player.init();
    player.playStateStream!.listen((state) async {
      _isPlaying.value = state.isPlaying;
      _isPlayCompleted.value = state.isPlayCompleted;
      _isBuffering.value = state.isBuffering;
      if (state.isPlayCompleted) {
        if (playMode == 0) {
          await setPlayIndex(playIndex.value + 1);
          await player.play();
        } else {
          await player.seek(0);
          await player.play();
        }
      }
    });

    player.durationStream!.listen((event) {
      _buffered.value = Duration(seconds: event.cacheDuration.round());
      _position.value = Duration(seconds: event.position.round());
      _duration.value = Duration(seconds: event.duration.round());
    });
  }

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

  @override
  void onInit() {
    super.onInit();
    _init();
    _initPlayer();
  }

  @override
  void onClose() {
    super.onClose();
    player.destroy();
    refreshController.dispose();
  }

  Future<void> refreshList([bool? clean = true]) async {
    _pageInfo = {'nextMarker': 'init', 'page': 0, 'hasMore': true};

    refreshController.loadComplete();

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
      type: MediaTagType.video,
    );

    for (var item in list) {
      _downloads[item.relationId] = item;
    }

    if (album.isAliyunPlatform) {
      var fileSize = await AliyunApi.getFolderSizeInfo(
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

    if (album.songIds.isNotEmpty) {
      var [ab] = await AlbumDbModel.findByIds([album.id]);
      _album.value = ab;
      videos.value = await MediaDbModel.findByIds(ab.songIds);
      refreshController.refreshCompleted();
      refreshController.loadNoData();
      return;
    }

    if (album.isAliyunPlatform && nextMarker.isNotEmpty) {
      await user.updateToken();
      var response = await AliyunApi.search(
        driveId: user.extra.driveId,
        xDeviceId: user.extra.xDeviceId,
        token: user.accessToken,
        xSignature: user.extra.xSignature,
        parentFileIds: [album.relationId],
        categorys: ["video"],
        limit: 20,
        marker:
            (nextMarker.isEmpty || nextMarker == 'init') ? null : nextMarker,
      ).getData();

      List<MediaDbModel> items = [];

      List<Future<void>> tasks = [];

      for (var item in response.items) {
        var song = MediaDbModel.fromAliFile(
          album: album,
          user: user,
          file: item,
          type: MediaTagType.video,
        );
        items.add(_downloads[item.fileId] ?? song);
        if (song.cover.startsWith('http')) {
          tasks.add(
            Tool.cacheImg(
              url: song.cover,
              cacheKey: '${MediaPlatformType.aliyun}@${item.fileId}',
              referer: song.extra.referer,
            ),
          );
        }
      }

      await Future.wait(tasks);

      if (nextMarker == 'init') {
        videos.value = items;
      } else {
        videos.addAll(items);
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
      var promise = album.isSelf == 1
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

      var response = await promise.getData();

      var items = response.medias
          .where((item) => !item.isExpire)
          .map(
            (item) =>
                _downloads[item.bvid] ??
                MediaDbModel.fromBili(
                  album: album,
                  user: user,
                  file: item,
                  type: MediaTagType.video,
                ),
          )
          .toList();
      if (page == 0) {
        videos.value = items;
      } else {
        videos.addAll(items);
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
    } else {
      refreshController.refreshCompleted();
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

  Future<void> setPlayIndex(int index) async {
    if (index == videos.length - 1) {
      await loadMoreList();
    }

    if (index > videos.length - 1) {
      index = 0;
    }

    var song = videos[index];
    var [_, video] = await song.getPlayUrl();

    String artUri = "";

    if (song.cover.startsWith('http')) {
      var oc = await CachedNetworkImageProvider.defaultCacheManager
          .getFileFromCache(song.cacheKey);
      if (oc != null && oc.file.existsSync()) {
        artUri = 'file://${oc.file.path}';
      } else {
        artUri = song.cover;
      }
    } else {
      artUri = 'file://${song.cover}';
    }

    var headers = {
      "referer": song.extra.referer,
      "origin": song.extra.referer,
      "User-Agent":
          'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36 Edg/131.0.0.0',
    };

    await player.setUrl(
      url: video,
      urlHeader: headers,
      cover: artUri,
      title: song.name,
      artist: song.artist,
    );

    playIndex.value = index;
  }

  void showVideoControl() {
    _videoControlTimer?.cancel();
    _videoControlFlag.value = true;
  }

  void hideVideoControl(int delay) {
    _videoControlTimer?.cancel();
    if (delay == 0) {
      _videoControlFlag.value = false;
      return;
    }
    _videoControlTimer = Timer(Duration(seconds: delay), () {
      _videoControlFlag.value = false;
    });
  }

  Future<void> handleRemove(List<MediaDbModel> videos) async {
    try {
      EasyLoading.show(
        status: '${"正在删除".tr}...',
        maskType: EasyLoadingMaskType.black,
      );
      if (album.isLocalPlatform &&
          album.relationId == MediaPlatformType.local.name) {
        for (var song in videos) {
          if (playIndex.value != -1 &&
              song.id == this.videos[playIndex.value].id) {
            await player.pause();
          }
          await Tool.deleteAsset(song.local);
          song.local = '';
          await song.update();
        }
      }
      if (album.isAliyunPlatform) {
        await user.updateToken();
        await AliyunApi.deleteFile(
          fileIds: videos.map((item) => item.relationId).toList(),
          driveId: user.extra.driveId,
          xDeviceId: user.extra.xDeviceId,
          token: user.accessToken,
          xSignature: user.extra.xSignature,
        ).getData();
      }
      if (album.isBiliPlatform) {
        await user.updateToken();
        await BiliApi.deleteFavVideo(
          cookie: user.accessToken,
          mediaId: album.relationId,
          resources: videos.map((item) => item.extra.resourceId).toList(),
        );
      }
      for (var video in videos) {
        if (playIndex.value != -1 &&
            video.id == this.videos[playIndex.value].id) {
          playIndex.value = 0;
        }
        this.videos.remove(video);
        var num = album.songIds.indexOf(video.id);
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

  Future<void> handleAddAlbum(List<MediaDbModel> videos) async {
    var completer = Completer();
    Tool.showBottomSheet(
      SizedBox(
        height: 800.w,
        child: AlbumSelectComp(
          isLocalPlatform: true,
          type: MediaTagType.video,
          excludes: [album.relationId],
          onSelect: (album) async {
            try {
              EasyLoading.show(
                status: '${"添加中".tr}...',
                maskType: EasyLoadingMaskType.black,
              );
              List<int> ids = [...album.songIds];
              MediaDbModel? first;
              for (var media in videos) {
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
                var file = await Tool.cacheImg(
                  url: first.cover,
                  cacheKey: first.cacheKey,
                );
                album.cover = file.path;
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

  Future<void> handleDownload(List<MediaDbModel> videos) async {
    try {
      EasyLoading.show(
        status: '${"添加下载任务中".tr}...',
        maskType: EasyLoadingMaskType.black,
      );
      var taskController = Get.find<TaskController>();
      for (var media in videos) {
        if (media.id == -1) {
          var id = await MediaDbModel.insert(media);
          media.id = id;
        }
        taskController.createTask(
          media: media,
          taskType: MediaTaskType.download,
          remark: '本地视频'.tr,
        );
      }
      EasyLoading.dismiss();
      EasyLoading.showToast('已添加下载任务'.tr);
    } catch (e) {
      EasyLoading.dismiss();
      EasyLoading.showToast('添加下载任务失败'.tr);
    }
  }

  Future<void> handleUpload(List<MediaDbModel> videos) async {
    var completer = Completer();

    Tool.showBottomSheet(
      SizedBox(
        height: 800.w,
        child: AlbumSelectComp(
          isLocalPlatform: false,
          type: MediaTagType.video,
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

              if (album.isAliyunPlatform) {
                var next = 'init';
                List<AliFile> items = [];
                while (next.isNotEmpty) {
                  var response = await AliyunApi.search(
                    driveId: user.extra.driveId,
                    xDeviceId: user.extra.xDeviceId,
                    token: user.accessToken,
                    xSignature: user.extra.xSignature,
                    parentFileIds: [album.relationId],
                    fileIds: videos.map((item) => item.relationId).toList(),
                    limit: 100,
                    marker: next == 'init' ? null : next,
                  ).getData();

                  next = response.nextMarker;
                  items.addAll(response.items);
                }
                temps = items.map((item) {
                  return MediaDbModel.fromAliFile(
                    album: album,
                    user: user,
                    file: item,
                    type: MediaTagType.video,
                  );
                }).toList();
              }

              var keys = temps.map((item) => item.relationId).toList();

              for (var item in videos) {
                if (keys.contains(item.relationId)) {
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
      for (var item in videos) {
        if (checkType.value == VideoCheckType.download) {
          if (item.local.isEmpty) {
            checkMaps[item.relationId] = item;
          }
        } else if (checkType.value == VideoCheckType.upload) {
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
    if (checkType.value == VideoCheckType.addAlbum) {
      await handleAddAlbum(list);
    }

    if (checkType.value == VideoCheckType.download) {
      await handleDownload(list);
    }

    if (checkType.value == VideoCheckType.delete) {
      await handleRemove(list);
    }

    if (checkType.value == VideoCheckType.upload) {
      await handleUpload(list);
    }

    checkMaps.clear();
    checkType.value = VideoCheckType.none;
  }

  setVideoMode(int mode) {
    _videoMode.value = mode;
  }

  Future<void> play() async {
    await player.play();
    Get.find<AudioController>().player.pause();
  }

  Future<void> pause() async {
    await player.pause();
  }

  Future<void> seek(Duration position) async {
    await player.seek(position.inSeconds.toDouble());
  }

  togglePlayMode() {
    _videoPlayMode.value = playMode == 0 ? 1 : 0;
  }
}

class VideoModelBinding implements Bindings {
  @override
  void dependencies() {
    Get.lazyPut<VideoModelController>(() => VideoModelController());
  }
}
