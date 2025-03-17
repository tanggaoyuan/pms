import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:pms/components/export.dart';
import 'package:pms/pages/album/export.dart';
import 'package:switch_orientation/switch_orientation.dart';
import 'package:video_player/video_player.dart';

class VideoFullPage extends StatefulWidget {
  const VideoFullPage({super.key});

  static String path = '/video/full';

  static Future? to() {
    return Get.toNamed(path);
  }

  static GetPage page = GetPage(
    name: path,
    page: () {
      return const VideoFullPage();
    },
    transition: Transition.rightToLeft,
  );

  @override
  State<StatefulWidget> createState() {
    return _VideoFullPageState();
  }
}

class _VideoFullPageState extends State<VideoFullPage> {
  var controller = Get.find<VideoModelController>();
  late PageController pageController;
  late Worker _worker;

  Widget renderVideoControllBar(BuildContext context) {
    var videoControlFlag = controller.videoControlFlag;
    var isPlaying = controller.isPlaying;
    var position = controller.position;
    var duration = controller.duration;
    var buffered = controller.buffered;
    var header = controller.header;

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
                              controller.setVideoMode(0);
                              Get.back();
                            },
                            icon: const Icon(
                              Icons.arrow_back_ios,
                              color: Colors.white,
                              size: 20,
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
                                    width: 30,
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
                                    width: 30,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                InkWell(
                                  onTap: () {
                                    controller.showVideoControl();
                                    controller.hideVideoControl(3);
                                    controller.setVideoMode(
                                      controller.isVertical ? 2 : 1,
                                    );
                                    if (controller.isHorizontal) {
                                      SwitchOrientation.setPreferredOrientations(
                                        [
                                          DeviceOrientation.landscapeLeft,
                                          DeviceOrientation.landscapeRight,
                                        ],
                                      );
                                    } else {
                                      SwitchOrientation.setPreferredOrientations(
                                        [
                                          DeviceOrientation.portraitUp,
                                          DeviceOrientation.portraitDown,
                                        ],
                                      );
                                    }
                                  },
                                  child: SizedBox(
                                    width: 30,
                                    height: 30,
                                    child: Stack(
                                      children: [
                                        Positioned(
                                          bottom: 0,
                                          right: 0,
                                          child: Opacity(
                                            opacity:
                                                controller.isVertical ? 1 : 0.6,
                                            child: const FaIcon(
                                              FontAwesomeIcons.mobile,
                                              color: Colors.white,
                                              size: 26,
                                            ),
                                          ),
                                        ),
                                        Positioned(
                                          bottom: 0,
                                          right: 0,
                                          child: Opacity(
                                            opacity:
                                                controller.isHorizontal
                                                    ? 1
                                                    : 0.5,
                                            child: const RotatedBox(
                                              quarterTurns: 3,
                                              child: FaIcon(
                                                FontAwesomeIcons.mobile,
                                                color: Colors.white,
                                                size: 26,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            height: 40,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Text(
                              header.name,
                              style: const TextStyle(
                                color: Colors.white,
                                overflow: TextOverflow.ellipsis,
                                fontSize: 12,
                              ),
                              softWrap: true,
                              maxLines: 2,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: ProgressBar(
                              progress: position,
                              buffered: buffered,
                              total: duration,
                              progressBarColor: Colors.white,
                              baseBarColor: Colors.white.withValues(alpha: .24),
                              bufferedBarColor: Colors.white.withValues(
                                alpha: .24,
                              ),
                              thumbColor: Colors.white,
                              barHeight: 4,
                              thumbRadius: 6,
                              thumbGlowRadius: 10,
                              timeLabelTextStyle: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
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
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                )
                : const SizedBox(),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    SwitchOrientation.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    pageController = PageController(initialPage: controller.playIndex.value);

    pageController.addListener(() async {
      var index = pageController.page ?? 0;
      if (index % 1 == 0) {
        var page = index % controller.videos.length;
        var old = controller.playIndex.value;
        if (page == old) return;
        await controller.setPlayIndex(page.toInt());
        await controller.play();
      }
    });
    _worker = ever(controller.playIndex, (index) {
      var page = (pageController.page ?? 0);
      var old = page % controller.videos.length;
      if (old != index) {
        pageController.jumpToPage(index);
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
    pageController.dispose();
    _worker.dispose();
    SwitchOrientation.setPreferredOrientations([DeviceOrientation.portraitUp]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: PageView.builder(
        scrollDirection: Axis.vertical,
        controller: pageController,
        itemBuilder: (_, index) {
          return GetX<VideoModelController>(
            builder: (controller) {
              var page = index % controller.videos.length;
              var video = controller.videos[page];
              var videoPlayController = controller.videoPlayController?.value;

              return Stack(
                children: [
                  GestureDetector(
                    onTap: () {
                      controller.showVideoControl();
                      controller.hideVideoControl(3);
                    },
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 500),
                      child:
                          controller.playIndex.value != page
                              ? Center(
                                child: ImgComp(
                                  source: video.cover,
                                  cacheKey: video.cacheKey,
                                  referer: video.extra.referer,
                                ),
                              )
                              : Center(
                                child:
                                    videoPlayController == null
                                        ? Video(
                                          controller:
                                              controller.videoController,
                                          controls: null,
                                        )
                                        : AspectRatio(
                                          aspectRatio:
                                              videoPlayController
                                                  .value
                                                  .aspectRatio,
                                          child: VideoPlayer(
                                            videoPlayController,
                                          ),
                                        ),
                              ),
                    ),
                  ),
                  renderVideoControllBar(context),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
