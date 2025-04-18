import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:pms/bindings/export.dart';
import 'package:pms/components/export.dart';
import 'package:pms/utils/export.dart';
import 'package:media_player_plugin/export.dart';
import 'package:string_normalizer/string_normalizer.dart';

class MusicPlayPage extends StatefulWidget {
  MusicPlayPage({super.key});
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

  @override
  State<StatefulWidget> createState() {
    return _MusicPlayPageState();
  }
}

class _MusicPlayPageState extends State<MusicPlayPage> {
  final audioController = Get.find<AudioController>();

  @override
  initState() {
    super.initState();
    audioController.player.enableFFT();
  }

  @override
  void dispose() {
    super.dispose();
    audioController.player.disableFFT();
  }

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
              referer: currentSong.extra.referer,
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
                StringNormalizer.normalize(currentSong.name),
                style: TextStyle(
                  color: Colors.white.withValues(alpha: .9),
                  fontSize: 32.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8.w),
              Text(
                StringNormalizer.normalize([
                  currentSong.platform.name,
                  currentSong.artist,
                  currentSong.albumName,
                ].where((item) => item.isNotEmpty).join(' • ')),
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
          Tool.showBottomSheet(
            SizedBox(height: 800.w, child: SongSheetComp(initIndex: 1)),
          );
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
            referer: currentSong.extra.referer,
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
                      child: showLyric.value
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
                        if (audioController.songs.isEmpty) {
                          EasyLoading.showToast("暂无播放数据");
                          return;
                        }

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
                        Tool.showBottomSheet(
                          SizedBox(height: 800.w, child: const SongSheetComp()),
                        );
                      },
                      icon: ImgComp(
                        source: ImgCompIcons.bars,
                        width: 40.w,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                Material(
                  color: Colors.transparent, // 保持背景透明
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: InkWell(
                    onTap: () async {
                      var bands = await audioController.player.getEqBands();
                      EqualizerView.show(
                        context: context,
                        bands: bands,
                        onChanged: (index, gain) {
                          audioController.player.updateBand(index, gain: gain);
                        },
                        height: 600.w,
                        enableEq: audioController.player.isEqActive,
                        onEqSwitchChanged: (value) {
                          if (value) {
                            audioController.player.enableEq();
                          } else {
                            audioController.player.disableEq();
                          }
                        },
                        onReset: () {
                          for (var i = 0; i < bands.length; i++) {
                            audioController.player.updateBand(i, gain: 0);
                          }
                        },
                      );
                    },
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                    overlayColor: WidgetStateProperty.resolveWith<Color?>((
                      states,
                    ) {
                      if (states.contains(WidgetState.pressed)) {
                        return Colors.black.withValues(alpha: .1); // 点击时添加深色覆盖
                      }
                      return null; // 未点击时保持原样
                    }),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: .0), // 上部完全透明
                            Colors.black.withValues(alpha: .2), // 下部黑色 20% 透明度
                          ],
                        ),
                      ),
                      child: FFtView(
                        controller: audioController.player,
                        width: Get.width,
                        indicatorWidth: 2,
                        spaceWidth: 1,
                        color: Colors.white,
                        indicatorHeight: 60,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}
