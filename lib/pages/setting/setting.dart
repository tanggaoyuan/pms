import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:pms/bindings/export.dart';
import 'package:pms/components/cache_buttom.dart';
import 'package:pms/pages/export.dart';
import 'package:pms/utils/export.dart';
import 'package:simple_ruler_picker/simple_ruler_picker.dart';

class SettingPage extends GetView<SettingController> {
  const SettingPage({super.key});

  @override
  Widget build(BuildContext context) {
    var themes = controller.themes;
    var locales = controller.locales;

    Widget renderTheme() {
      return Obx(() {
        return Container(
          padding: EdgeInsets.only(left: 30.w),
          width: double.infinity,
          decoration: BoxDecoration(
            color: controller.theme.appBarTheme.backgroundColor,
            borderRadius: BorderRadius.circular(20.w),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text('主题色'.tr, style: TextStyle(fontSize: 28.sp)),
                  ),
                  Transform.scale(
                    scale: 0.6,
                    child: Switch(
                      value: controller.isDarkMode,
                      onChanged: (value) {
                        controller.toggleThemeMode();
                      },
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10.w),
              Wrap(
                spacing: 10.w,
                runSpacing: 10.w,
                children:
                    themes.asMap().entries.map((item) {
                      var index = item.key;
                      var theme = item.value;
                      return GestureDetector(
                        child: Opacity(
                          opacity: index == controller.themeIndex ? 1 : 0.5,
                          child: Container(
                            width: 90.w,
                            height: 90.w,
                            decoration: BoxDecoration(
                              color: theme.light.primaryColor,
                              borderRadius: BorderRadius.all(
                                Radius.circular(6.w),
                              ),
                            ),
                          ),
                        ),
                        onTap: () {
                          controller.selectTheme(index);
                        },
                      );
                    }).toList(),
              ),
              SizedBox(height: 30.w),
            ],
          ),
        );
      });
    }

    Widget renderLang() {
      return Obx(() {
        return Container(
          padding: EdgeInsets.only(left: 30.w, top: 20.w),
          width: double.infinity,
          decoration: BoxDecoration(
            color: controller.theme.appBarTheme.backgroundColor,
            borderRadius: BorderRadius.circular(20.w),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('语言'.tr, style: TextStyle(fontSize: 28.sp)),
              SizedBox(height: 10.w),
              Wrap(
                spacing: 10.w,
                runSpacing: 10.w,
                children:
                    locales.asMap().entries.map((item) {
                      var index = item.key;
                      var locale = item.value;
                      var bg =
                          controller.isDarkMode ? Colors.black : Colors.white;
                      var active = controller.localIndex == index;
                      return GestureDetector(
                        child: Opacity(
                          opacity: active ? 1 : 0.5,
                          child: Container(
                            width: 90.w,
                            height: 90.w,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.all(
                                Radius.circular(6.w),
                              ),
                              color: bg,
                            ),
                            child: Center(child: Text(locale.toString().tr)),
                          ),
                        ),
                        onTap: () {
                          controller.selectLocal(index);
                        },
                      );
                    }).toList(),
              ),
              SizedBox(height: 30.w),
            ],
          ),
        );
      });
    }

    Widget renderHeadset() {
      return Obx(() {
        var audioController = Get.find<AudioController>();

        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: controller.theme.appBarTheme.backgroundColor,
            borderRadius: BorderRadius.circular(20.w),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () {
                      var fc = controller.theme.primaryColor.withValues(
                        alpha: .8,
                      );
                      var title = TextStyle(
                        fontSize: 28.sp,
                        height: 2,
                        color: fc,
                      );
                      var text = TextStyle(fontSize: 26.sp, color: fc);
                      Tool.showBottomSheet(
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(20.w),
                          child: ListView(
                            children: [
                              Center(
                                child: Text(
                                  "耳机辅助功能说明".tr,
                                  style: TextStyle(fontSize: 30.sp),
                                ),
                              ),
                              SizedBox(height: 20.w),
                              Text('启用/关闭：'.tr, style: title),
                              Text('• 通过长按/3次点击进行切换'.tr, style: text),
                              SizedBox(height: 20.w),
                              Text('辅助功能关闭情况：'.tr, style: title),
                              Text('• 中键点击播放/暂停，双击播放下一首'.tr, style: text),
                              Text('• 音量键调节声音'.tr, style: text),
                              SizedBox(height: 20.w),
                              Text('辅助功能开启情况：'.tr, style: title),
                              SizedBox(height: 10.w),
                              Text('• 正常模式'.tr, style: text),
                              SizedBox(height: 10.w),
                              Text('  - 中键点击播放/暂停，双击切换模式'.tr, style: text),
                              Text('  - 音量键调节声音'.tr, style: text),
                              SizedBox(height: 10.w),
                              Text('• 歌曲切换模式'.tr, style: text),
                              SizedBox(height: 10.w),
                              Text(
                                '  - 中键点击切换播放模式列表播放/单曲循环/随机播放，双击切换模式'.tr,
                                style: text,
                              ),
                              Text('  - 音量键上一曲/下一曲'.tr, style: text),
                              SizedBox(height: 10.w),
                              Text('• 定时模式'.tr, style: text),
                              SizedBox(height: 10.w),
                              Text('  - 中键点击启用/关闭定时，双击切换模式'.tr, style: text),
                              Text('  - 音量键增加/减少时间，单位为15分钟'.tr, style: text),
                            ],
                          ),
                        ),
                      );
                    },
                    icon: FaIcon(FontAwesomeIcons.circleInfo, size: 30.w),
                  ),
                  Expanded(
                    child: Text('耳机辅助功能'.tr, style: TextStyle(fontSize: 28.sp)),
                  ),
                  Transform.scale(
                    scale: 0.6,
                    child: Switch(
                      value: audioController.enableHeadsetMode.value,
                      onChanged: (value) {
                        // audioController.toggleHeadsetMode();
                      },
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      });
    }

    Widget renderTimeMode() {
      return Obx(() {
        var audioController = Get.find<AudioController>();

        return Container(
          width: double.infinity,
          padding: EdgeInsets.only(left: 30.w),
          decoration: BoxDecoration(
            color: controller.theme.appBarTheme.backgroundColor,
            borderRadius: BorderRadius.circular(20.w),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('定时关闭'.tr, style: TextStyle(fontSize: 28.sp)),
                  SizedBox(width: 20.w),
                  Expanded(
                    child: Text(
                      Duration(
                        seconds: audioController.time.value,
                      ).toString().split('.').first,
                      style: TextStyle(fontSize: 26.sp),
                    ),
                  ),
                  Transform.scale(
                    scale: 0.6,
                    child: Switch(
                      value: audioController.enableTimeMode.value,
                      onChanged: (value) {
                        audioController.toggleTimeMode();
                      },
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ],
              ),
              SizedBox(
                height: 140.w,
                width: double.infinity,
                child: SimpleRulerPicker(
                  height: 140.w,
                  minValue: 0,
                  maxValue: 12 * 60,
                  initialValue: (audioController.time.value / 60).round(),
                  scaleLabelWidth: 10.w,
                  selectedColor: controller.theme.primaryColor,
                  scaleLabelSize: 20.sp,
                  lineStroke: 2.w,
                  longLineHeight: 30.sp,
                  scaleBottomPadding: 0,
                  shortLineHeight: 10,
                  scaleItemWidth: 18.w.toInt(),
                  lineColor: Colors.grey,
                  onValueChanged: (value) {
                    audioController.time.value = value * 60;
                  },
                ),
              ),
              SizedBox(height: 20.w),
            ],
          ),
        );
      });
    }

    return Scaffold(
      appBar: AppBar(title: Text('设置'.tr)),
      body: Container(
        padding: EdgeInsets.all(20.w),
        width: double.infinity,
        child: ListView(
          children: [
            renderTheme(),
            SizedBox(height: 20.w),
            renderLang(),
            SizedBox(height: 20.w),
            // renderHeadset(),
            // SizedBox(height: 20.w),
            renderTimeMode(),
            SizedBox(height: 20.w),
            const CacheButtomComp(),
            TextButton(
              onPressed: () async {
                // DbHelper.removeTable(MediaDbModel.tableName);

                // var users = await UserDbModel.users();

                // await users.last.remove();

                // users.forEach((item) {
                //   print(item.toMap());
                // });

                // AudioPlayerTest.to();
                VideoPlayerTest.to();
              },
              child: Text('测试'),
            ),
          ],
        ),
      ),
    );
  }

  static String path = '/setting';

  static to() {
    return Get.toNamed(path);
  }

  static GetPage page = GetPage(
    name: path,
    page: () {
      return const SettingPage();
    },
    transition: Transition.rightToLeft,
  );
}
