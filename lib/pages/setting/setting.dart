import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:pms/bindings/export.dart';
import 'package:pms/components/cache_buttom.dart';
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
                children: themes.asMap().entries.map((item) {
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
                children: locales.asMap().entries.map((item) {
                  var index = item.key;
                  var locale = item.value;
                  var bg = controller.isDarkMode ? Colors.black : Colors.white;
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
