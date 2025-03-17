import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:pms/bindings/export.dart';
import 'package:pms/components/export.dart';
import 'package:pms/utils/export.dart';

class MusicPlayPage extends StatelessWidget {
  MusicPlayPage({super.key});

  final audioController = Get.find<AudioController>();

  static String path = '/muisc/play';

  static to() {
    return Get.toNamed(path);
  }

  static GetPage page = GetPage(
    name: path,
    page: () {
      return MusicPlayPage();
    },
    transition: Transition.rightToLeft,
  );

  String getPlayModeIcon(PlayMode playMode) {
    switch (playMode) {
      case PlayMode.one:
        return ImgCompIcons.singleTunePlay;
      case PlayMode.order:
        return ImgCompIcons.orderPlay;
      case PlayMode.random:
        return ImgCompIcons.randomPlay;
    }
  }

  Widget renderCover() {
    var currentSong = audioController.currentSong!;
    return Column(
      children: [
        Expanded(
          child: Center(
            child: ImgComp(
              source: currentSong.cover,
              cacheKey: currentSong.cacheKey,
              width: 450.w,
              radius: 30.w,
              fit: BoxFit.cover,
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 30.w),
          child: Column(
            children: [
              Text(
                currentSong.name,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: .9),
                  fontSize: 32.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8.w),
              Text(
                [
                  currentSong.platform.name,
                  currentSong.artist,
                  currentSong.albumName,
                ].where((item) => item.isNotEmpty).join(' • '),
                style: TextStyle(
                  color: Colors.white.withValues(alpha: .9),
                  fontSize: 24.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget renderLyric(BuildContext context) {
    var currentSong = audioController.currentSong!;

    if (currentSong.lyric.mainLrc.isEmpty) {
      return GestureDetector(
        onTap: () {
          Tool.showBottomSheet(const SongSheetComp(initIndex: 1));
        },
        child: Center(
          child: Text(
            '匹配歌词'.tr,
            style: TextStyle(
              fontSize: 32.sp,
              color: Colors.white.withValues(alpha: .8),
              height: 1.5,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      );
    }

    return MusicLyricComp(
      lrc: currentSong.lyric,
      position: audioController.position.value,
      onPositionChanged: (position) {
        audioController.player.seek(position.inSeconds.toDouble());
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      var currentSong = audioController.currentSong!;
      var showLyric = audioController.showLyric;

      return Scaffold(
        body: ObscureComp(
          obscureColor: Colors.black.withValues(alpha: .1),
          background: ImgComp(
            source: currentSong.cover,
            width: Get.width,
            cacheKey: currentSong.cacheKey,
            height: Get.height,
            fit: BoxFit.cover,
          ),
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
                    size: 30.w,
                    color: Colors.white.withValues(alpha: .8),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      showLyric.value = !showLyric.value;
                    },
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 500),
                      child:
                          showLyric.value
                              ? renderLyric(context)
                              : renderCover(),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(30.w),
                  child: ProgressBar(
                    progress: audioController.position.value,
                    buffered: audioController.cachePosition.value,
                    total: audioController.duration.value,
                    progressBarColor: Colors.white,
                    baseBarColor: Colors.white.withValues(alpha: 0.24),
                    bufferedBarColor: Colors.white.withValues(alpha: 0.24),
                    thumbColor: Colors.white,
                    barHeight: 6.w,
                    thumbRadius: 10.w,
                    thumbGlowRadius: 24.w,
                    timeLabelTextStyle: TextStyle(
                      color: Colors.white,
                      fontSize: 24.sp,
                    ),
                    onSeek: (duration) {
                      audioController.player.seek(
                        duration.inSeconds.toDouble(),
                      );
                    },
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    IconButton(
                      onPressed: () {
                        audioController.togglePlayMode();
                      },
                      icon: ImgComp(
                        source: getPlayModeIcon(audioController.playMode.value),
                        color: Colors.white,
                        width: 50.w,
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        audioController.prev();
                      },
                      icon: FaIcon(
                        FontAwesomeIcons.backwardStep,
                        color: Colors.white,
                        size: 50.w,
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        if (audioController.playing.value) {
                          audioController.player.pause();
                        } else {
                          audioController.player.play();
                        }
                      },
                      icon: FaIcon(
                        audioController.playing.value
                            ? FontAwesomeIcons.solidCirclePause
                            : FontAwesomeIcons.solidCirclePlay,
                        color: Colors.white,
                        size: 80.w,
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        audioController.next();
                      },
                      icon: FaIcon(
                        FontAwesomeIcons.forwardStep,
                        color: Colors.white,
                        size: 50.w,
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        Tool.showBottomSheet(const SongSheetComp());
                      },
                      icon: ImgComp(
                        source: ImgCompIcons.bars,
                        width: 40.w,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 60.w),
              ],
            ),
          ),
        ),
      );
    });
  }
}
