import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pms/bindings/export.dart';
import 'package:pms/utils/export.dart';
import 'package:sqflite/sqflite.dart';

class CacheButtomComp extends StatefulWidget {
  const CacheButtomComp({super.key});

  @override
  _CacheButtomCompState createState() => _CacheButtomCompState();
}

class _CacheButtomCompState extends State<CacheButtomComp> {
  final SettingController settingController = Get.find<SettingController>();

  late String cacheSize = '';

  @override
  initState() {
    super.initState();
    init();
  }

  clearCache() {
    var taskController = Get.find<TaskController>();
    if (taskController.downloads.isNotEmpty ||
        taskController.formats.isNotEmpty) {
      EasyLoading.showToast('当前有下载任务或转码任务正在进行，请等待完成后再清理缓存'.tr);
      return;
    }

    Tool.showConfirm(
        title: '提示'.tr,
        content: '删除缓存将会导致部分列表图片无法展示，需要对列表进行刷新操作'.tr,
        onConfirm: () async {
          EasyLoading.show(
              status: '清理缓存中...'.tr, maskType: EasyLoadingMaskType.black);
          try {
            await CachedNetworkImageProvider.defaultCacheManager.emptyCache();
            var cache = await getApplicationCacheDirectory();
            await cache.delete(recursive: true);
            String cachePath = await getDatabasesPath();
            final hiveDir = Directory("$cachePath/hive");
            if (hiveDir.existsSync()) {
              hiveDir.deleteSync(recursive: true);
            }
            EasyLoading.showToast('清理缓存成功'.tr);
            init();
          } catch (e) {
            Tool.log(e);
            EasyLoading.showToast('清理缓存失败'.tr);
          }
        });
  }

  init() async {
    var cache = await getApplicationCacheDirectory();
    var size = Tool.getDirectorySize(cache);
    cacheSize = Tool.formatSize(size);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      var theme = settingController.theme;
      return TextButton(
        style: ButtonStyle(
          backgroundColor:
              WidgetStatePropertyAll(theme.primaryColor.withValues(alpha: .1)),
        ),
        onPressed: () {
          clearCache();
        },
        child: Text(
          cacheSize.isEmpty ? '计算缓存大小中...'.tr : '${'清理缓存'.tr} $cacheSize',
          style: TextStyle(
            fontSize: 28.sp,
          ),
        ),
      );
    });
  }
}
