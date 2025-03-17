import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_xlider/flutter_xlider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:pms/components/export.dart';
import 'package:pms/db/export.dart';
import 'package:pms/pages/export.dart';
import 'package:pms/utils/export.dart';

class VideoCutPage extends StatefulWidget {
  const VideoCutPage({super.key});

  @override
  State<StatefulWidget> createState() {
    return _VideoCutPageState();
  }

  static String path = '/video/cut';

  static Future? to(MediaDbModel model) {
    return Get.toNamed(path, arguments: model);
  }

  static GetPage page = GetPage(
    name: path,
    page: () {
      return const VideoCutPage();
    },
    transition: Transition.rightToLeft,
  );
}

class _VideoCutPageState extends State<VideoCutPage> {
  var model = Get.arguments as MediaDbModel;
  late List<double> ranges = [0, 100];
  late List<double> values = [0, 1];
  late int index = -1;

  final Player _player = Player();
  late VideoController videoController;

  late bool isPlaying = false;
  late int position = 0;
  late String cover;
  late String name;
  late String albumName;
  late String art;

  init() async {
    setState(() {
      cover = model.cover;
      name = model.name;
      albumName = model.albumName;
      art = model.artist;
    });
    var platform = _player.platform;
    if (platform is NativePlayer) {
      await platform.setProperty("volume-max", "100");
    }
    Tool.log(['model.local', model.local]);
    await _player.open(Media(model.local), play: false);
  }

  @override
  void initState() {
    super.initState();
    videoController = VideoController(_player);

    _player.stream.playing.listen((event) {
      setState(() {
        isPlaying = event;
      });
    });

    _player.stream.position.listen((event) {
      if (event.inSeconds >= values.last) {
        _player.pause();
      }
      setState(() {
        position = isPlaying ? event.inSeconds - values.first.toInt() : 0;
      });
    });

    _player.stream.duration.listen((duration) {
      var end = duration.inSeconds.toDouble();
      if (end == 0) {
        return;
      }
      setState(() {
        ranges = [0, end];
        values = ranges;
      });
    });

    init();
  }

  @override
  dispose() {
    super.dispose();
    _player.pause();
    _player.dispose();
  }

  Widget renderSlider() {
    var primaryColor = Get.theme.primaryColor;
    var barColor = Color.lerp(primaryColor, Colors.white, 0.6);

    FlutterSliderHandler renderSliderBlock(int value) {
      return FlutterSliderHandler(
        decoration: BoxDecoration(
          color: index == value ? primaryColor : barColor,
          borderRadius: BorderRadius.circular(15.w),
        ),
        child: const SizedBox(),
      );
    }

    return FlutterSlider(
      values: values,
      max: ranges.last,
      min: ranges.first,
      rangeSlider: true,
      handlerWidth: 30.w,
      handlerHeight: 30.w,
      handler: renderSliderBlock(0),
      rightHandler: renderSliderBlock(1),
      touchSize: 5,
      trackBar: FlutterSliderTrackBar(
        activeTrackBarHeight: 12.w,
        inactiveTrackBarHeight: 12.w,
        inactiveTrackBar: BoxDecoration(
          borderRadius: BorderRadius.circular(6.w),
        ),
        activeTrackBar: BoxDecoration(
          borderRadius: BorderRadius.circular(6.w),
          color: barColor,
        ),
      ),
      step: const FlutterSliderStep(step: 1),
      tooltip: FlutterSliderTooltip(
        positionOffset: FlutterSliderTooltipPositionOffset(top: 40.w),
        custom: (value) {
          var text =
              Duration(
                seconds: (value as double).toInt(),
              ).toString().split('.').first;
          return Container(
            padding: EdgeInsets.all(10.w),
            decoration: BoxDecoration(
              color: Get.theme.scaffoldBackgroundColor,
              borderRadius: BorderRadius.circular(10.w),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withValues(alpha: .5),
                  spreadRadius: 1.w,
                  blurRadius: 1.w,
                  offset: Offset(1.w, 1.w),
                ),
              ],
            ),
            child: Text(
              text,
              style: TextStyle(fontSize: 32.w, color: primaryColor),
            ),
          );
        },
      ),
      onDragCompleted: (handlerIndex, lowerValue, upperValue) async {
        await _player.pause();
        if (values.first != lowerValue) {
          index = 0;
          _player.seek(Duration(seconds: (lowerValue as double).toInt()));
        }
        if (values.last != upperValue) {
          index = 1;
          _player.seek(Duration(seconds: (upperValue as double).toInt()));
        }
        values = [lowerValue, upperValue];
        setState(() {});
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: Video(controller: videoController, controls: null),
            ),
          ),
          Container(
            alignment: Alignment.center,
            width: double.infinity,
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(30.w),
                topRight: Radius.circular(30.w),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    ImgComp(
                      source: cover,
                      cacheKey: model.cacheKey,
                      referer: model.extra.referer,
                      width: 100.w,
                      fit: BoxFit.cover,
                      radius: 10.w,
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: TextStyle(
                              fontSize: 26.sp,
                              overflow: TextOverflow.ellipsis,
                            ),
                            textAlign: TextAlign.left,
                            maxLines: 1,
                          ),
                          Opacity(
                            opacity: 0.7,
                            child: Text(
                              '$art/$albumName',
                              style: TextStyle(
                                fontSize: 24.sp,
                                overflow: TextOverflow.ellipsis,
                              ),
                              textAlign: TextAlign.left,
                              maxLines: 1,
                            ),
                          ),
                          SizedBox(height: 8.w),
                          Container(
                            height: 10.w,
                            decoration: BoxDecoration(
                              color: Get.theme.primaryColor.withValues(
                                alpha: .1,
                              ),
                              borderRadius: BorderRadius.circular(10.w),
                            ),
                            alignment: Alignment.centerLeft,
                            child: FractionallySizedBox(
                              widthFactor:
                                  position / (values.last - values.first),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Get.theme.primaryColor,
                                  borderRadius: BorderRadius.circular(10.w),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20.w),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      onPressed: () async {
                        Tool.showBottomSheet(
                          MediaOperationComp(
                            name: name,
                            albumName: albumName,
                            art: art,
                            onSave: ({
                              required String albumName,
                              required String art,
                              required String name,
                            }) {
                              this.art = art;
                              this.albumName = albumName;
                              this.name = name;
                              setState(() {});
                            },
                          ),
                        );
                      },
                      icon: FaIcon(FontAwesomeIcons.filePen, size: 40.w),
                    ),
                    IconButton(
                      onPressed: () async {
                        try {
                          EasyLoading.show(
                            status: '设置封面中'.tr,
                            maskType: EasyLoadingMaskType.black,
                          );
                          var buffers = await _player.screenshot();
                          if (buffers == null) {
                            throw '';
                          }
                          var dirpath = await Tool.getCoverStorePath();
                          var savepath =
                              '$dirpath/${DateTime.now().toString()}.jpeg';

                          await Directory(dirpath).create(recursive: true);
                          final file = File(savepath);
                          await file.writeAsBytes(buffers);
                          if (cover != model.cover) {
                            await File(cover).delete();
                          }
                          setState(() {
                            cover = savepath;
                          });
                          EasyLoading.dismiss();
                        } catch (e) {
                          EasyLoading.dismiss();
                          EasyLoading.showToast('获取异常'.tr);
                        }
                      },
                      icon: FaIcon(FontAwesomeIcons.camera, size: 40.w),
                    ),
                    IconButton(
                      onPressed: () async {
                        values[index]--;
                        await _player.pause();
                        _player.seek(Duration(seconds: values[index].toInt()));
                        setState(() {});
                      },
                      icon: FaIcon(FontAwesomeIcons.anglesLeft, size: 40.w),
                    ),
                    IconButton(
                      onPressed: () async {
                        if (isPlaying) {
                          await _player.pause();
                        } else {
                          await _player.seek(
                            Duration(seconds: values.first.toInt()),
                          );
                          await _player.play();
                        }
                      },
                      icon: FaIcon(
                        isPlaying
                            ? FontAwesomeIcons.pause
                            : FontAwesomeIcons.play,
                        size: 40.w,
                      ),
                    ),
                    IconButton(
                      onPressed: () async {
                        values[index]++;
                        await _player.pause();
                        _player.seek(Duration(seconds: values[index].toInt()));
                        setState(() {});
                      },
                      icon: FaIcon(FontAwesomeIcons.anglesRight, size: 40.w),
                    ),
                  ],
                ),
                SizedBox(height: 10.w),
                renderSlider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      Duration(
                        seconds: values.first.toInt(),
                      ).toString().split('.').first,
                    ),
                    Text(
                      Duration(
                        seconds: values.last.toInt(),
                      ).toString().split('.').first,
                    ),
                  ],
                ),
                SizedBox(height: 40.w),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    TextButton(
                      style: ButtonStyle(
                        padding: WidgetStatePropertyAll(EdgeInsets.all(10.w)),
                        minimumSize: WidgetStatePropertyAll(Size(140.w, 60.w)),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        backgroundColor: WidgetStatePropertyAll(
                          Get.theme.primaryColor.withValues(alpha: .1),
                        ),
                      ),
                      onPressed: () async {
                        try {
                          EasyLoading.show(
                            status: '提取音频中...'.tr,
                            maskType: EasyLoadingMaskType.black,
                          );
                          var dirpath = model.local.substring(
                            0,
                            model.local.lastIndexOf('/'),
                          );
                          await Directory(dirpath).create(recursive: true);
                          var output = '$dirpath/${name.split('.').first}.flac';
                          var outputFile = File(output);

                          handle([bool del = true]) async {
                            if (del) {
                              await outputFile.delete();
                            }
                            await FfmpegTool.convertAudio(
                              input: model.local,
                              output: output,
                              startTime: values.first,
                              endTime: values.last,
                              coverPath: cover,
                              onProgress: (progress, duration) async {
                                EasyLoading.showProgress(
                                  progress / 100,
                                  maskType: EasyLoadingMaskType.black,
                                );
                              },
                            );
                            var media = MediaDbModel(
                              name: name,
                              albumName: albumName,
                              cover: cover,
                              artist: art,
                              platform: MediaPlatformType.local,
                              local: output,
                              type: MediaTagType.muisc,
                            );
                            var id = await MediaDbModel.insert(media);
                            media.id = id;
                            var [album] = await AlbumDbModel.findByRelationIds(
                              ids: [MediaPlatformType.local.name],
                              type: media.type,
                            );
                            album.songIds.add(media.id);
                            await album.update();
                            Get.find<HomeController>().initMuiceAlbums();
                            Get.back();
                            EasyLoading.dismiss();
                          }

                          if (outputFile.existsSync()) {
                            EasyLoading.dismiss();
                            Tool.showConfirm(
                              title: '操作'.tr,
                              content: '存在同名文件是否覆盖'.tr,
                              onConfirm: handle,
                            );
                            return;
                          }
                          await handle(false);
                        } catch (e) {
                          Tool.log(['ee', e]);
                          EasyLoading.dismiss();
                          EasyLoading.showToast('转码异常'.tr);
                        }
                      },
                      child: Text('存为音频'.tr, style: TextStyle(fontSize: 26.sp)),
                    ),
                    TextButton(
                      style: ButtonStyle(
                        padding: WidgetStatePropertyAll(EdgeInsets.all(10.w)),
                        minimumSize: WidgetStatePropertyAll(Size(140.w, 60.w)),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        backgroundColor: WidgetStatePropertyAll(
                          Get.theme.primaryColor.withValues(alpha: .1),
                        ),
                      ),
                      onPressed: () async {
                        try {
                          EasyLoading.show(
                            status: '提取音频中...'.tr,
                            maskType: EasyLoadingMaskType.black,
                          );
                          var dirpath = model.local.substring(
                            0,
                            model.local.lastIndexOf('/'),
                          );
                          await Directory(dirpath).create(recursive: true);
                          var output = '$dirpath/${name.split('.').first}.mp4';
                          var outputFile = File(output);

                          handle([bool del = true]) async {
                            if (del) {
                              await outputFile.delete();
                            }
                            await FfmpegTool.cropVideo(
                              input: model.local,
                              output: output,
                              startTime: values.first,
                              endTime: values.last,
                              onProgress: (progress, duration) async {
                                EasyLoading.showProgress(
                                  progress / 100,
                                  maskType: EasyLoadingMaskType.black,
                                );
                              },
                            );
                            var media = MediaDbModel(
                              name: name,
                              albumName: albumName,
                              cover: cover,
                              artist: art,
                              platform: MediaPlatformType.local,
                              local: output,
                              type: MediaTagType.video,
                            );
                            var id = await MediaDbModel.insert(media);
                            media.id = id;
                            var [album] = await AlbumDbModel.findByRelationIds(
                              ids: [MediaPlatformType.local.name],
                              type: media.type,
                            );
                            album.songIds.add(media.id);
                            await album.update();
                            Get.find<HomeController>().initVideoAlbums();
                            Get.back();
                            EasyLoading.dismiss();
                          }

                          if (outputFile.existsSync()) {
                            EasyLoading.dismiss();
                            Tool.showConfirm(
                              title: '操作'.tr,
                              content: '存在同名文件是否覆盖'.tr,
                              onConfirm: handle,
                            );
                            return;
                          }
                          await handle(false);
                        } catch (e) {
                          EasyLoading.dismiss();
                          EasyLoading.showToast('转码异常'.tr);
                        }
                      },
                      child: Text('保存'.tr, style: TextStyle(fontSize: 26.sp)),
                    ),
                    TextButton(
                      style: ButtonStyle(
                        padding: WidgetStatePropertyAll(EdgeInsets.all(10.w)),
                        minimumSize: WidgetStatePropertyAll(Size(140.w, 60.w)),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        backgroundColor: WidgetStatePropertyAll(
                          Get.theme.primaryColor.withValues(alpha: .1),
                        ),
                      ),
                      onPressed: () {
                        Get.back();
                      },
                      child: Text('返回'.tr, style: TextStyle(fontSize: 26.sp)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
