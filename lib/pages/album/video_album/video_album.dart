import 'dart:async';
import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:pms/components/export.dart';
import 'package:pms/db/export.dart';
import 'package:pms/pages/album/export.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:pms/utils/export.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:video_player/video_player.dart';

class VideoAlbumPage extends GetView<VideoModelController> {
  const VideoAlbumPage({super.key});

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

    return Obx(() {
      var chckType = controller.checkType;
      var checkMaps = controller.checkMaps;
      var album = controller.album;

      List<Widget> children = [];

      if (chckType.value != VideoCheckType.none) {
        children = [
          SizedBox(width: 20.w),
          Expanded(
            child: Text(
              '${'已选择'.tr} ${checkMaps.length}',
              style: TextStyle(fontSize: 24.sp),
            ),
          ),
          renderNavButton(text: '全选'.tr, onPressed: controller.checkAll),
          renderNavButton(
            text: '取消'.tr,
            onPressed: () {
              checkMaps.value = {};
              chckType.value = VideoCheckType.none;
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
              '${album.songIds.isNotEmpty ? album.songIds.length : album.count}${'条数据'.tr}',
              style: TextStyle(fontSize: 24.sp),
            ),
          ),
          if (album.isSelf == 1)
            renderNavButton(
              text: '删除'.tr,
              onPressed: () async {
                chckType.value = VideoCheckType.delete;
              },
            ),
          renderNavButton(
            text: '上传'.tr,
            onPressed: () async {
              chckType.value = VideoCheckType.upload;
            },
          ),
          if (!album.isLocalMainAlbum)
            renderNavButton(
              text: '下载'.tr,
              onPressed: () {
                chckType.value = VideoCheckType.download;
              },
            ),
          renderNavButton(
            text: '添加到专辑'.tr,
            onPressed: () {
              chckType.value = VideoCheckType.addAlbum;
            },
          ),
          SizedBox(width: 20.w),
        ];
      }

      return Positioned(
        bottom: 0,
        left: 0,
        right: 0,
        child: ClipRRect(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20.w),
            topRight: Radius.circular(20.w),
          ),
          child: Container(
            height: 90.w,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.9),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: children,
            ),
          ),
        ),
      );
    });
  }

  Widget renderHeader() {
    var fontColor = Colors.white;

    return Obx(() {
      var header = controller.header;
      var user = controller.user;
      var isPlaying = controller.isPlaying;
      var album = controller.album;
      var videoController = controller.videoController;
      var videoControlFlag = controller.videoControlFlag;
      var headerHeight = 500.w;
      var contentHeight = 410.w;
      var playIndex = controller.playIndex;
      var position = controller.position;
      var duration = controller.duration;
      var buffered = controller.buffered;
      var isNone = controller.isNone;
      var videoPlayController = controller.videoPlayController?.value;

      Widget renderCover() {
        return SafeArea(
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () {
                      Get.back();
                    },
                    icon: Icon(Icons.arrow_back, size: 26, color: fontColor),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    album.name,
                    style: TextStyle(fontSize: 19, color: fontColor),
                  ),
                ],
              ),
              SizedBox(height: 10.w),
              const Expanded(child: SizedBox()),
              Padding(
                padding: EdgeInsets.all(10.w),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Text(
                        header.name,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 32.sp,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        softWrap: true,
                      ),
                    ),
                    IconButton(
                      onPressed: () async {
                        await controller.setPlayIndex(0);
                        await controller.play();
                      },
                      icon: FaIcon(
                        FontAwesomeIcons.solidCirclePlay,
                        size: 80.w,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }

      Widget renderVideo() {
        return GestureDetector(
          onTap: () {
            controller.showVideoControl();
            controller.hideVideoControl(3);
          },
          child:
              videoPlayController == null
                  ? Video(
                    controller: videoController,
                    controls: NoVideoControls,
                  )
                  : AspectRatio(
                    aspectRatio: videoPlayController.value.aspectRatio,
                    child: VideoPlayer(videoPlayController),
                  ),
        );
      }

      Widget renderVideoControllBar() {
        return Positioned.fill(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 500),
            child:
                videoControlFlag
                    ? GestureDetector(
                      onTap: () {
                        controller.showVideoControl();
                        controller.hideVideoControl(3);
                      },
                      child: Container(
                        color: Colors.black.withValues(alpha: .3),
                        child: SafeArea(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              IconButton(
                                onPressed: () {
                                  Get.back();
                                },
                                icon: Icon(
                                  Icons.arrow_back_ios,
                                  color: Colors.white,
                                  size: 30.w,
                                ),
                              ),
                              Expanded(
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    IconButton(
                                      onPressed: () {
                                        controller.showVideoControl();
                                        controller.hideVideoControl(3);
                                        if (isPlaying) {
                                          controller.pause();
                                        } else {
                                          controller.play();
                                        }
                                      },
                                      icon: ImgComp(
                                        source:
                                            isPlaying
                                                ? ImgCompIcons.pause
                                                : ImgCompIcons.play,
                                        color: Colors.white,
                                        width: 50.w,
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: () {
                                        controller.showVideoControl();
                                        controller.hideVideoControl(3);
                                        controller.togglePlayMode();
                                      },
                                      icon: ImgComp(
                                        source:
                                            controller.playMode == 0
                                                ? ImgCompIcons.orderPlay
                                                : ImgCompIcons.singleTunePlay,
                                        width: 50.w,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    InkWell(
                                      onTap: () {
                                        controller.setVideoMode(1);
                                        VideoFullPage.to();
                                      },
                                      child: Padding(
                                        padding: EdgeInsets.only(
                                          right: 20.w,
                                          bottom: 14.w,
                                          left: 14.w,
                                        ),
                                        child: SizedBox(
                                          width: 50.w,
                                          height: 50.w,
                                          child: Stack(
                                            children: [
                                              Positioned(
                                                bottom: 0.w,
                                                right: 0.w,
                                                child: Opacity(
                                                  opacity: 0.8,
                                                  child: FaIcon(
                                                    FontAwesomeIcons.mobile,
                                                    color: Colors.white,
                                                    size: 46.w,
                                                  ),
                                                ),
                                              ),
                                              Positioned(
                                                bottom: 0.w,
                                                right: 0.w,
                                                child: Opacity(
                                                  opacity: 0.7,
                                                  child: RotatedBox(
                                                    quarterTurns: 3,
                                                    child: FaIcon(
                                                      FontAwesomeIcons.mobile,
                                                      color: Colors.white,
                                                      size: 46.w,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 20.w),
                                height: 40.w,
                                child: Text(
                                  header.name,
                                  maxLines: 1,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 22.sp,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 20.w,
                                ).copyWith(bottom: 20.w),
                                child: ProgressBar(
                                  progress: position,
                                  buffered: buffered,
                                  total: duration,
                                  progressBarColor: Colors.white,
                                  baseBarColor: Colors.white.withValues(
                                    alpha: .24,
                                  ),
                                  bufferedBarColor: Colors.white.withValues(
                                    alpha: .24,
                                  ),
                                  thumbColor: Colors.white,
                                  barHeight: 6.w,
                                  thumbRadius: 10.w,
                                  thumbGlowRadius: 24.w,
                                  timeLabelTextStyle: TextStyle(
                                    color: Colors.white,
                                    fontSize: 24.sp,
                                  ),
                                  onSeek: (duration) {
                                    controller.seek(duration);
                                  },
                                  onDragStart: (details) {
                                    controller.showVideoControl();
                                  },
                                  onDragEnd: () {
                                    controller.hideVideoControl(3);
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                    : const SizedBox(),
          ),
        );
      }

      return Stack(
        children: [
          ImgComp(
            source: header.cover,
            cacheKey: header.cacheKey,
            height: headerHeight,
            width: double.infinity,
            fit: BoxFit.cover,
            referer: user.extra.referer,
          ),
          Positioned.fill(
            child: Container(color: Colors.black.withValues(alpha: .15)),
          ),
          Stack(
            children: [
              SizedBox(
                height: contentHeight,
                width: double.infinity,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 500),
                  child:
                      playIndex.value >= 0 && isNone
                          ? renderVideo()
                          : renderCover(),
                ),
              ),
              renderVideoControllBar(),
            ],
          ),
          renderHeaderBar(),
        ],
      );
    });
  }

  Widget renderList() {
    return Obx(() {
      var refreshController = controller.refreshController;
      var videos = controller.videos;
      var album = controller.album;
      var user = controller.user;
      var checkType = controller.checkType.value;
      var checkMaps = controller.checkMaps.value;

      Widget renderCheck(MediaDbModel video) {
        var enableDownload =
            checkType == VideoCheckType.download && video.local.isEmpty;
        var enableUpload =
            checkType == VideoCheckType.upload && video.local.isNotEmpty;
        var enableDelete = checkType == VideoCheckType.delete;
        if (enableDownload || enableUpload || enableDelete) {
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
            itemCount: videos.length,
            itemBuilder: (_, index) {
              var video = videos[index];
              return LongPressMenu(
                onPress: () async {
                  await controller.setPlayIndex(index);
                  await controller.play();
                },
                menus: [
                  if (album.isLocalMainAlbum)
                    PopupMenuItem<String>(
                      value: 'extract',
                      onTap: () async {
                        await VideoCutPage.to(video);
                        controller.refreshList();
                      },
                      child: Text('裁剪'.tr),
                    ),
                  if (video.local.isNotEmpty)
                    PopupMenuItem<String>(
                      value: 'upload',
                      onTap: () {
                        controller.handleUpload([video]);
                      },
                      child: Text('上传'.tr),
                    ),
                  if (video.local.isEmpty)
                    PopupMenuItem<String>(
                      value: 'download',
                      onTap: () async {
                        controller.handleDownload([video]);
                      },
                      child: Text('下载'.tr),
                    ),
                  PopupMenuItem<String>(
                    value: 'addAlbum',
                    onTap: () async {
                      controller.handleAddAlbum([video]);
                    },
                    child: Text('添加歌单'.tr),
                  ),
                  if (album.isSelf == 1)
                    PopupMenuItem<String>(
                      value: 'delete',
                      onTap: () {
                        Tool.showConfirm(
                          title: '是否删除？'.tr,
                          content: '是否删除'.tr,
                          onConfirm: () async {
                            controller.handleRemove([video]);
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
                            video.cover.isEmpty
                                ? ImgCompIcons.mainCover
                                : video.cover,
                        referer: user.extra.referer,
                        cacheKey: video.cacheKey,
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
                              video.name,
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
                                  video.platform.name,
                                  video.artist,
                                  video.albumName,
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
                      renderCheck(video),
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
    return Scaffold(body: Column(children: [renderHeader(), renderList()]));
  }

  static String path = '/video/album';

  static Future? to(AlbumDbModel model) {
    return Get.toNamed(path, arguments: model);
  }

  static GetPage page = GetPage(
    name: path,
    page: () {
      return const VideoAlbumPage();
    },
    binding: VideoModelBinding(),
    transition: Transition.rightToLeft,
  );
}
