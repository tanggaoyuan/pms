import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:pms/components/export.dart';
import 'package:pms/db/export.dart';
import 'package:pms/pages/export.dart';
import 'package:pms/utils/export.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

class MusicAlbumPage extends GetView<MusicModelController> {
  const MusicAlbumPage({super.key});

  Widget renderHeaderBar() {
    Widget renderNavButton({
      required String text,
      required void Function() onPressed,
      Color? color,
    }) {
      return Container(
        height: 40.w,
        padding: EdgeInsets.symmetric(horizontal: 8.w),
        child: OutlinedButton(
          style: ButtonStyle(
            padding: WidgetStatePropertyAll(
              EdgeInsets.symmetric(horizontal: 10.w),
            ),
            minimumSize: const WidgetStatePropertyAll(Size.zero),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            backgroundColor: WidgetStatePropertyAll(color),
          ),
          onPressed: onPressed,
          child: Text(text, style: TextStyle(fontSize: 22.sp)),
        ),
      );
    }

    List<Widget> children = [];

    var checkType = controller.checkType.value;
    var checkMaps = controller.checkMaps.value;
    var album = controller.album;

    if (checkType != MusicCheckType.none) {
      children = [
        SizedBox(width: 20.w),
        Expanded(
          child: Text(
            '${'已选择'.tr}${checkMaps.length}',
            style: TextStyle(fontSize: 24.sp),
          ),
        ),
        renderNavButton(text: '全选'.tr, onPressed: controller.checkAll),
        renderNavButton(
          text: '取消'.tr,
          onPressed: () {
            controller.checkType.value = MusicCheckType.none;
            controller.checkMaps.value = {};
          },
        ),
        if (checkMaps.isNotEmpty)
          renderNavButton(
            text: '确定'.tr,
            color: Colors.white,
            onPressed: controller.confirmCheck,
          ),
        SizedBox(width: 20.w),
      ];
    } else {
      children = [
        SizedBox(width: 20.w),
        Expanded(
          child: Text(
            '${album.songIds.isNotEmpty ? album.songIds.length : album.count}${'首'.tr}',
            style: TextStyle(fontSize: 24.sp),
          ),
        ),
        if (album.isSelf == 1)
          renderNavButton(
            text: '删除'.tr,
            onPressed: () async {
              controller.checkType.value = MusicCheckType.delete;
            },
          ),
        if (album.isLocalMainAlbum)
          renderNavButton(
            text: '上传'.tr,
            onPressed: () async {
              controller.checkType.value = MusicCheckType.upload;
            },
          ),
        if (!album.isLocalMainAlbum)
          renderNavButton(
            text: '下载'.tr,
            onPressed: () {
              controller.checkType.value = MusicCheckType.download;
            },
          ),
        renderNavButton(
          text: '添加到专辑'.tr,
          onPressed: () {
            controller.checkType.value = MusicCheckType.addAlbum;
          },
        ),
        SizedBox(width: 20.w),
      ];
    }

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        height: 90.w,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.9),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20.w),
            topRight: Radius.circular(20.w),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: children,
        ),
      ),
    );
  }

  Widget renderHeader() {
    return Obx(() {
      var fontColor = Colors.white;
      var header = controller.header;
      var user = controller.user;
      var album = controller.album;
      var isAlbumPlaying = controller.isAlbumPlaying;
      var isMusicPlaying = controller.isMusicPlaying;
      var player = controller.player;

      return Stack(
        children: [
          ImgComp(
            source: header.cover,
            cacheKey: header.cacheKey,
            height: 500.w,
            width: double.infinity,
            fit: BoxFit.cover,
            referer: user.extra.referer,
          ),
          ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 30.0, sigmaY: 30.0),
              child: Container(
                height: 500.w,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: .2),
                ),
                child: SafeArea(
                  child: Column(
                    children: [
                      Row(
                        children: [
                          IconButton(
                            onPressed: () {
                              Get.back();
                            },
                            icon: Icon(
                              Icons.arrow_back,
                              size: 26,
                              color: fontColor,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Text(
                            album.name,
                            style: TextStyle(fontSize: 19, color: fontColor),
                          ),
                        ],
                      ),
                      SizedBox(height: 10.w),
                      Row(
                        children: [
                          SizedBox(width: 30.w),
                          Stack(
                            children: [
                              Positioned(
                                right: 40.w,
                                top: 6.w,
                                child: ImgComp(
                                  source: ImgCompIcons.compactDisc,
                                  width: 180.w,
                                  color: Colors.black.withValues(alpha: .5),
                                ),
                              ),
                              Container(
                                margin: EdgeInsets.only(right: 80.w),
                                child: ImgComp(
                                  source: header.cover,
                                  cacheKey: header.cacheKey,
                                  width: 200.w,
                                  fit: BoxFit.cover,
                                  radius: 20.w,
                                  referer: user.extra.referer,
                                ),
                              ),
                            ],
                          ),
                          Expanded(
                            child: Column(
                              children: [
                                Text(
                                  header.name,
                                  style: TextStyle(
                                    color: fontColor.withValues(alpha: .8),
                                    fontSize: 30.sp,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  softWrap: true,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                ),
                                SizedBox(height: 10.w),
                                IconButton(
                                  onPressed: () {
                                    if (isAlbumPlaying) {
                                      isMusicPlaying
                                          ? player.pause()
                                          : player.play();
                                    } else {
                                      controller.playAlbum(0);
                                    }
                                  },
                                  icon: FaIcon(
                                    controller.isMusicPlaying
                                        ? FontAwesomeIcons.solidCirclePause
                                        : FontAwesomeIcons.solidCirclePlay,
                                    size: 70.w,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: 40.w),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          renderHeaderBar(),
        ],
      );
    });
  }

  Widget renderList() {
    return Obx(() {
      var refreshController = controller.refreshController;
      var songs = controller.songs;
      var album = controller.album;
      var user = controller.user;
      var checkType = controller.checkType.value;
      var checkMaps = controller.checkMaps.value;

      Widget renderCheck(MediaDbModel video) {
        var enableDownload =
            checkType == MusicCheckType.download && video.local.isEmpty;
        var enableUpload =
            checkType == MusicCheckType.upload && video.local.isNotEmpty;
        var enableDelete = checkType == MusicCheckType.delete;
        var enableAddAlbum = checkType == MusicCheckType.addAlbum;
        if (enableDownload || enableUpload || enableDelete || enableAddAlbum) {
          return AbsorbPointer(
            absorbing: false,
            child: Checkbox(
              value: checkMaps[video.relationId] != null,
              onChanged: (value) {
                if (value == true) {
                  controller.checkMaps[video.relationId] = video;
                } else {
                  controller.checkMaps.remove(video.relationId);
                }
              },
            ),
          );
        }
        return const SizedBox();
      }

      return Expanded(
        child: SmartRefresher(
          controller: refreshController,
          onRefresh: controller.refreshList,
          onLoading: controller.loadMoreList,
          enablePullDown: true,
          enablePullUp: true,
          child: ListView.builder(
            itemCount: songs.length,
            itemBuilder: (_, index) {
              var song = songs[index];
              return LongPressMenu(
                onPress: () async {
                  controller.playAlbum(index);
                },
                menus: [
                  if (song.local.isNotEmpty)
                    PopupMenuItem<String>(
                      value: 'upload',
                      onTap: () {
                        controller.handleUpload([song]);
                      },
                      child: Text('上传'.tr),
                    ),
                  if (song.local.isEmpty)
                    PopupMenuItem<String>(
                      value: 'download',
                      onTap: () async {
                        controller.handleDownload([song]);
                      },
                      child: Text('下载'.tr),
                    ),
                  PopupMenuItem<String>(
                    value: 'addAlbum',
                    onTap: () async {
                      controller.handleAddAlbum([song]);
                    },
                    child: Text('添加歌单'.tr),
                  ),
                  if (album.isSelf == 1)
                    PopupMenuItem<String>(
                      value: 'delete',
                      onTap: () {
                        Tool.showConfirm(
                          title: '提示'.tr,
                          content: '是否删除'.tr,
                          onConfirm: () async {
                            controller.handleRemove([song]);
                          },
                        );
                      },
                      child: Text('删除'.tr),
                    ),
                ],
                child: Padding(
                  padding: EdgeInsets.all(10.w),
                  child: Row(
                    children: [
                      ImgComp(
                        source:
                            song.cover.isEmpty
                                ? ImgCompIcons.mainCover
                                : song.cover,
                        referer: user.extra.referer,
                        cacheKey: song.cacheKey,
                        width: 100.w,
                        radius: 10.w,
                        fit: BoxFit.cover,
                      ),
                      SizedBox(width: 20.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              song.name,
                              softWrap: true,
                              maxLines: 1,
                              style: TextStyle(
                                fontSize: 28.sp,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            SizedBox(height: 6.w),
                            Opacity(
                              opacity: 0.6,
                              child: Text(
                                [
                                  song.platform.name,
                                  song.artist,
                                  song.albumName,
                                ].where((item) => item.isNotEmpty).join(' • '),
                                style: TextStyle(
                                  fontSize: 22.sp,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                softWrap: true,
                                maxLines: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                      renderCheck(song),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Column(children: [renderHeader(), renderList()]),
          const Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SongBottomBarComp(),
          ),
        ],
      ),
    );
  }

  static String path = '/muisc/album';

  static Future? to(AlbumDbModel model) {
    return Get.toNamed(path, arguments: model);
  }

  static GetPage page = GetPage(
    name: path,
    page: () {
      return const MusicAlbumPage();
    },
    binding: MusicModelBinding(),
    transition: Transition.rightToLeft,
  );
}
