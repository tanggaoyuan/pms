import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:pms/bindings/export.dart';
import 'package:pms/components/export.dart';
import 'package:pms/db/export.dart';
import 'package:pms/pages/export.dart';
import 'package:pms/utils/export.dart';
import 'package:string_normalizer/string_normalizer.dart';

class SongBottomBarComp extends StatelessWidget {
  const SongBottomBarComp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetX<AudioController>(
      builder: (controller) {
        if (controller.currentSong == null) {
          return const SizedBox();
        }
        return const _SongBottomBar();
      },
    );
  }
}

class _SongBottomBar extends StatefulWidget {
  const _SongBottomBar();

  @override
  _SongBottomBarState createState() => _SongBottomBarState();
}

class _SongBottomBarState extends State<_SongBottomBar> {
  late PageController pageController;
  late Worker _worker;

  final audioController = Get.find<AudioController>();
  final settingController = Get.find<SettingController>();

  bool lock = false;

  int topage(int value) {
    return value + 1;
  }

  @override
  void initState() {
    super.initState();

    pageController = PageController(
      initialPage: topage(audioController.current.value),
    );

    pageController.addListener(() {
      var lenght = audioController.songs.length + 2;

      if (pageController.page == 0) {
        pageController.jumpToPage(lenght - 2);
      }

      if (pageController.page == lenght - 1) {
        pageController.jumpToPage(1);
      }
    });

    _worker = ever(audioController.current, (value) async {
      if (!pageController.hasClients) {
        return;
      }
      var page = topage(value);
      if (pageController.page!.round() != page) {
        lock = true;
        pageController.jumpToPage(page);
        lock = false;
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
    pageController.dispose();
    _worker.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      var theme = settingController.theme;
      var song = audioController.currentSong;

      var songs = audioController.songs.isNotEmpty
          ? [
              audioController.songs.last,
              ...audioController.songs,
              audioController.songs.first,
            ]
          : [
              MediaDbModel(
                  name: "暂无播放数据".tr,
                  platform: MediaPlatformType.local,
                  type: MediaTagType.action)
            ];

      return Container(
        width: double.infinity,
        height: 110.w,
        decoration: BoxDecoration(
          color: theme.bottomNavigationBarTheme.backgroundColor?.withValues(
            alpha: .7,
          ),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20.w),
            topRight: Radius.circular(20.w),
          ),
        ),
        child: ObscureComp(
          background: ImgComp(
            source: song?.cover ?? ImgCompIcons.mainCover,
            fit: BoxFit.cover,
            cacheKey: song?.cacheKey,
            width: double.infinity,
            radius: 10.w,
            referer: song?.extra.referer,
          ),
          obscureColor: theme.scaffoldBackgroundColor.withValues(alpha: .6),
          child: Row(
            children: [
              Expanded(
                child: PageView.builder(
                  itemCount: songs.length,
                  controller: pageController,
                  onPageChanged: (page) {
                    if (page == 0 || page == songs.length - 1) {
                      return;
                    }
                    if (lock) return;
                    audioController.play(page - 1);
                  },
                  itemBuilder: (_, index) {
                    var song = songs[index];
                    return TextButton(
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero, // 移除内边距
                        minimumSize: Size.zero, // 允许按钮更小
                        tapTargetSize:
                            MaterialTapTargetSize.shrinkWrap, // 缩小点击区域
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20.w), // 添加圆角
                        ),
                      ),
                      onPressed: () {
                        MusicPlayPage.to();
                      },
                      child: Padding(
                        padding: EdgeInsets.all(10.w).copyWith(left: 20.w),
                        child: Row(
                          children: [
                            Container(
                              width: 80.w,
                              height: 80.w,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10.w),
                                boxShadow: [
                                  BoxShadow(
                                    color: theme.primaryColor.withValues(
                                      alpha: .25,
                                    ),
                                    blurRadius: 5.w,
                                    offset: Offset(-2.w, 2.w),
                                  ),
                                ],
                              ),
                              child: ImgComp(
                                source: song.cover,
                                fit: BoxFit.cover,
                                cacheKey: song.cacheKey,
                                width: 80.w,
                                radius: 10.w,
                                referer: song.extra.referer,
                              ),
                            ),
                            SizedBox(width: 20.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    StringNormalizer.normalize(song.name),
                                    style: TextStyle(
                                      fontSize: 26.sp,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    maxLines: 1,
                                  ),
                                  SizedBox(height: 6.w),
                                  Text(
                                    StringNormalizer.normalize(
                                        song.platform.name),
                                    style: TextStyle(
                                      fontSize: 22.sp,
                                      color: theme.primaryColor.withValues(
                                        alpha: .6,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(width: 20.w),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              IconButton(
                onPressed: () {
                  if (audioController.songs.isEmpty) {
                    EasyLoading.showToast("暂无播放数据".tr);
                    return;
                  }

                  if (audioController.playing.value) {
                    audioController.player.pause();
                  } else {
                    audioController.player.play();
                  }
                },
                icon: ImgComp(
                  source: audioController.playing.value
                      ? ImgCompIcons.pause
                      : ImgCompIcons.play,
                  width: 35.w,
                ),
              ),
              IconButton(
                onPressed: () {
                  Tool.showBottomSheet(
                    SizedBox(height: 800.w, child: const SongSheetComp()),
                  );
                },
                icon: ImgComp(source: ImgCompIcons.bars, width: 35.w),
              ),
            ],
          ),
        ),
      );
    });
  }
}
