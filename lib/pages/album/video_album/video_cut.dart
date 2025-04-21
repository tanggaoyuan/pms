import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_xlider/flutter_xlider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:media_player_plugin/export.dart';
import 'package:pms/components/export.dart';
import 'package:pms/db/export.dart';
import 'package:pms/pages/export.dart';
import 'package:pms/utils/export.dart';
import 'package:string_normalizer/string_normalizer.dart';

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
  var isInit = false;
  late int index = -1;

  final MediaVideoPlayer player = MediaVideoPlayer();

  late bool isPlaying = false;
  late int position = 0;
  late String cover = "";
  late String name = "";
  late String albumName = "";
  late String art = "";

  final List<StreamSubscription> _subs = [];

  init() async {

    await player.init();

    _subs.add(
      player.playStateStream!.listen((event) {
        setState(() {
          isPlaying = event.isPlaying;
        });
      })
    );

    _subs.add(
      player.durationStream!.listen((event) {
        if (event.position >= values.last) {
          player.pause();
        }

        if (!isInit) {
          isInit = true;
          var end = event.duration;
          if (end == 0) {
            return;
          }
          setState(() {
            ranges = [0, end];
            values = ranges;
          });
        }

        setState(() {
            position =
                isPlaying ? max(event.position.toInt() - values.first.toInt(), 0) : 0;
          });
        })
    );


    setState(() {
      cover = model.cover;
      name = StringNormalizer.normalize(model.name);
      albumName = StringNormalizer.normalize(model.albumName);
      art = StringNormalizer.normalize(model.artist);
    });

    await player.setUrl(url: "file://${model.assetAbsolutePath}");
    await player.prepare();

  }

  @override
  void initState() {
    super.initState();
    init();
  }

  @override
  dispose() {
    super.dispose();
    for (var item in _subs) {
      item.cancel();
    }
    player.destroy();
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
          var text = Duration(
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
        await player.pause();
        if (values.first != lowerValue) {
          index = 0;
          player.seek(lowerValue);
        }
        if (values.last != upperValue) {
          index = 1;
          player.seek(upperValue);
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
              child: MediaVideoView(controller: player),
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
                        values[index]--;
                        await player.pause();
                        player.seek(values[index]);
                        setState(() {});
                      },
                      icon: FaIcon(FontAwesomeIcons.anglesLeft, size: 40.w),
                    ),
                    IconButton(
                      onPressed: () async {
                        if (isPlaying) {
                          await player.pause();
                        } else {
                          await player.seek(values.first);
                          await player.play();
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
                        await player.pause();
                        player.seek(values[index]);
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

                           var relativePath = model.local.substring(
                            0,
                            model.local.lastIndexOf('/'),
                          );

                          await Directory("${Tool.appAssetsPath}$relativePath").create(recursive: true);

                          relativePath = "$relativePath/${name.split('.').first}.flac";

                          var output = '${Tool.appAssetsPath}$relativePath';

                          var outputFile = File(output);


                          handle([bool del = true]) async {
                            if (del) {
                              await outputFile.delete();
                            }
                            await FfmpegTool.convertAudio(
                              input: model.assetAbsolutePath,
                              output: outputFile.path,
                              startTime: values.first,
                              endTime: values.last,
                              coverPath: cover.startsWith("/")?"${Tool.coverStorePath}$cover":cover,
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
                              local: relativePath,
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
                          
                          
                          var relativePath = model.local.substring(
                            0,
                            model.local.lastIndexOf('/'),
                          );

                          await Directory("${Tool.appAssetsPath}$relativePath").create(recursive: true);

                          relativePath = "$relativePath/${name.split('.').first}.mp4";

                          var output = '${Tool.appAssetsPath}$relativePath';

                          var outputFile = File(output);

                          handle([bool del = true]) async {
                            if (del) {
                              await outputFile.delete();
                            }
                            await FfmpegTool.cropVideo(
                              input: model.assetAbsolutePath,
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
                              local: relativePath,
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
                          Tool.log(['ee', e]);
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
