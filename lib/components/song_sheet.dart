import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:pms/apis/export.dart';
import 'package:pms/bindings/export.dart';
import 'package:pms/db/export.dart';
import 'package:string_normalizer/string_normalizer.dart';

class SongSheetComp extends StatefulWidget {
  final Function(NetLrc lyric)? onLyricChange;
  final int? initIndex;
  const SongSheetComp({super.key, this.onLyricChange, this.initIndex});

  @override
  State createState() => _SongSheetCompState();
}

class _SongSheetCompState extends State<SongSheetComp>
    with SingleTickerProviderStateMixin {
  final controller = Get.find<AudioController>();

  late ScrollController _controller;
  late TabController _tabController;
  late PageController _pageController;
  late List<NetSong> lyrics = [];
  late String keywork = '';
  late Worker _worker;
  var isLoading = false;

  @override
  void initState() {
    super.initState();
    var index = controller.current.value;
    var offset = (index - 2) * 90.w;
    _controller = ScrollController(
      initialScrollOffset: offset < 0 ? 0 : offset,
    );
    _tabController = TabController(
      initialIndex: widget.initIndex ?? 0,
      vsync: this,
      length: 2,
    );
    _pageController = PageController(initialPage: widget.initIndex ?? 0);

    keywork = controller.currentSong!.name;
    searchLyric();

    _worker = ever(controller.current, (_) {
      keywork = controller.currentSong!.name;
      searchLyric();
    });
  }

  @override
  void dispose() {
    super.dispose();
    _controller.dispose();
    _pageController.dispose();
    _tabController.dispose();
    _worker.dispose();
  }

  searchLyric() async {
    // var [user] = await UserDbModel.findByPlatform(MediaPlatformType.netease);
    var response = await NeteaseApi.search(
      keyword: keywork,
      // cookie: user.accessToken,
      limit: 20,
    ).setLocalCache(24 * 60 * 60 * 1000).getData();
    setState(() {
      lyrics = response.songs;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      var theme = Get.theme;
      var current = controller.current.value;

      var songs = controller.songs;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TabBar(
            controller: _tabController,
            onTap: (page) {
              _pageController.animateToPage(
                page,
                duration: const Duration(milliseconds: 200),
                curve: Curves.bounceIn,
              );
            },
            tabs: [Tab(text: '播放列表'.tr), Tab(text: '歌词匹配'.tr)],
            dividerColor: Colors.white,
          ),
          SizedBox(height: 10.w),
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (page) {
                _tabController.animateTo(page);
              },
              children: [
                ListView.builder(
                  controller: _controller,
                  itemCount: songs.length,
                  itemExtent: 90.w,
                  itemBuilder: (_, index) {
                    var song = songs[index];
                    return InkWell(
                      onTap: () {
                        if (current == index) {
                          return;
                        }
                        controller.play(index);
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 24.w),
                        color: current == index
                            ? theme.primaryColor.withValues(alpha: .05)
                            : null,
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                StringNormalizer.normalize(song.name),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: 28.sp),
                              ),
                            ),
                            SizedBox(width: 20.w),
                            IconButton(
                              onPressed: isLoading
                                  ? null
                                  : () async {
                                      try {
                                        setState(() {
                                          isLoading = true;
                                        });
                                        controller.songs.removeAt(index);
                                        if (songs.isEmpty) {
                                          controller.current.value = -1;
                                          await controller.player.pause();
                                        } else if (current == index) {
                                          if (songs.length - 1 > index) {
                                            await controller.play(index);
                                          } else {
                                            await controller
                                                .play(songs.length - 1);
                                          }
                                        } else {
                                          if (current > index) {
                                            controller.current.value--;
                                          }
                                        }
                                        await controller
                                            .setPlayList(controller.songs);
                                        setState(() {
                                          isLoading = false;
                                        });
                                      } catch (e) {
                                        setState(() {
                                          isLoading = false;
                                        });
                                      }
                                    },
                              icon: Icon(
                                Icons.close,
                                size: 32.sp,
                                color: theme.primaryColor.withValues(alpha: .2),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                Column(
                  children: [
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 20.w,
                        vertical: 14.w,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 70.w,
                              width: double.infinity,
                              child: TextField(
                                style: TextStyle(fontSize: 24.w),
                                decoration: InputDecoration(
                                  fillColor: theme.primaryColor.withValues(
                                    alpha: .03,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(30.w),
                                    borderSide: BorderSide.none,
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide.none,
                                    borderRadius: BorderRadius.circular(30.w),
                                  ),
                                  filled: true,
                                  labelText: '歌词关键字'.tr,
                                  labelStyle: TextStyle(fontSize: 24.w),
                                  hintStyle: TextStyle(fontSize: 24.w),
                                  contentPadding: EdgeInsets.symmetric(
                                    vertical: 10.w,
                                    horizontal: 20.w,
                                  ),
                                ),
                                onChanged: (value) {
                                  keywork = value;
                                },
                              ),
                            ),
                          ),
                          SizedBox(width: 10.w),
                          TextButton(
                            style: ButtonStyle(
                              minimumSize: WidgetStatePropertyAll(
                                Size(100.w, 70.w),
                              ),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              backgroundColor: WidgetStatePropertyAll(
                                theme.primaryColor.withValues(alpha: .03),
                              ),
                            ),
                            onPressed: () {
                              searchLyric();
                            },
                            child: Text(
                              '搜索'.tr,
                              style: TextStyle(fontSize: 24.sp),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: lyrics.length,
                        itemBuilder: (_, index) {
                          var song = lyrics[index];
                          return InkWell(
                            onTap: () async {
                              try {
                                EasyLoading.show(
                                  status: '设置歌词中...'.tr,
                                  maskType: EasyLoadingMaskType.black,
                                );
                                var response = await NeteaseApi.getLyric(
                                  song.id,
                                ).setLocalCache(double.infinity).getData();
                                if (response.mainLrc.isEmpty) {
                                  EasyLoading.dismiss();
                                  EasyLoading.showToast('歌词不存在'.tr);
                                  return;
                                }
                                controller.currentSong!.lyric = response;
                                await controller.currentSong!.update();
                                if (widget.onLyricChange != null) {
                                  widget.onLyricChange!(response);
                                }
                                EasyLoading.dismiss();
                                EasyLoading.showToast('设置成功'.tr);
                                Get.back();
                              } catch (e) {
                                EasyLoading.dismiss();
                                EasyLoading.showToast('获取歌词异常'.tr);
                              }
                            },
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 24.w,
                                vertical: 10.w,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Opacity(
                                    opacity: 0.8,
                                    child: Text(
                                      song.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(fontSize: 30.sp),
                                    ),
                                  ),
                                  Opacity(
                                    opacity: 0.5,
                                    child: Text(
                                      [song.albumName, song.alia.join('/')]
                                          .where((item) => item.isNotEmpty)
                                          .join(' • '),
                                      style: TextStyle(
                                        fontSize: 24.sp,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      maxLines: 1,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      );
    });
  }
}
