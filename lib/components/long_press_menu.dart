import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pms/bindings/export.dart';
import 'package:pms/utils/export.dart';

// ignore: must_be_immutable
class LongPressMenu extends GetView<SettingController> {
  final Widget child;

  void Function()? onPress;

  final List<PopupMenuItem> menus;

  Offset offset = Offset.zero;

  LongPressMenu({
    super.key,
    required this.child,
    this.onPress,
    required this.menus,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPress,
      onTapDown: (details) {
        offset = details.localPosition;
      },
      onLongPress: menus.isNotEmpty
          ? () {
              Tool.showMenuPosition(
                context: context,
                items: menus,
                offset: offset,
              );
            }
          : null,
      child: child,
    );
  }
}
