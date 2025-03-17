// ignore_for_file: must_be_immutable

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:pms/bindings/export.dart';
import 'package:pms/components/export.dart';
import 'package:pms/db/export.dart';
import 'package:pms/utils/tool.dart';

class AlbumItemComp extends GetView<SettingController> {
  final void Function()? onPress;
  final Future<void> Function()? onDelete;
  final Future<void> Function()? onShare;

  /// 可为string 和 widget
  final AlbumDbModel model;

  late Offset offset = const Offset(0, 0);

  /// 专辑的Item
  AlbumItemComp(
    this.model, {
    super.key,
    this.onPress,
    this.onDelete,
    this.onShare,
  });

  renderCover() {
    return Obx(() {
      var bgcolor = controller.theme.primaryColor.withValues(alpha: .1);
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(10.w)),
          color: bgcolor,
        ),
        width: 100.w,
        height: 100.w,
        child: Center(
          child: ImgComp(
            source: model.cover.isEmpty ? ImgCompIcons.cover : model.cover,
            width: 100.w,
            radius: 10.w,
            fit: BoxFit.cover,
            color: [
              ImgCompIcons.localMusic,
              ImgCompIcons.localVideo,
              ImgCompIcons.importFile,
              ImgCompIcons.albumPlus
            ].contains(model.cover)
                ? controller.theme.primaryColor
                : null,
          ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return LongPressMenu(
      onPress: onPress,
      menus: [
        if (onShare != null)
          PopupMenuItem<String>(
            value: 'share',
            onTap: onShare!,
            child: Text('分享'.tr),
          ),
        if (onDelete != null)
          PopupMenuItem<String>(
            value: 'delete',
            onTap: () {
              Tool.showConfirm(
                title: '是否删除？'.tr,
                content: '是否删除该数据'.tr,
                onConfirm: onDelete!,
              );
            },
            child: Text('删除'.tr),
          ),
      ],
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 10.w),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            renderCover(),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    model.name.tr,
                    style: TextStyle(fontSize: 30.sp),
                  ),
                  SizedBox(height: 10.w),
                  Opacity(
                    opacity: 0.6,
                    child: Text(
                      '${model.platform.name} ${model.platform != MediaPlatformType.action ? ' • ${model.count} ${'条'.tr}' : ''}',
                      style: TextStyle(fontSize: 24.sp),
                    ),
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
