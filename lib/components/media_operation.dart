// ignore_for_file: must_be_immutable

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

class MediaOperationComp extends StatelessWidget {
  final Function({
    required String name,
    required String albumName,
    required String art,
  }) onSave;
  final _formKey = GlobalKey<FormState>();

  late String name;
  late String albumName;
  late String art;

  MediaOperationComp({
    super.key,
    required this.onSave,
    this.name = '',
    this.albumName = '',
    this.art = '',
  });

  Widget renderInput({
    required String value,
    required String labelText,
    required Function(String? value) onSaved,
    bool allowEmpty = true,
  }) {
    return SizedBox(
      height: 80.w,
      child: TextFormField(
        initialValue: value,
        style: TextStyle(fontSize: 24.w),
        decoration: InputDecoration(
          fillColor: Get.theme.primaryColor.withValues(alpha: .1),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20.w),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide.none,
            borderRadius: BorderRadius.circular(20.w),
          ),
          filled: true,
          labelText: labelText,
          labelStyle: TextStyle(fontSize: 24.w),
          hintStyle: TextStyle(fontSize: 24.w),
          contentPadding:
              EdgeInsets.symmetric(vertical: 10.w, horizontal: 20.w),
        ),
        validator: allowEmpty
            ? null
            : (value) {
                if (value == null || value.isEmpty) {
                  return '请输入'.tr;
                }
                return null;
              },
        onSaved: onSaved,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(30.w),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            Text(
              '修改信息'.tr,
              style: TextStyle(fontSize: 30.sp),
            ),
            SizedBox(
              height: 20.w,
            ),
            renderInput(
              value: name,
              labelText: '媒体名称'.tr,
              onSaved: (value) {
                name = value ?? '';
              },
            ),
            SizedBox(
              height: 30.w,
            ),
            renderInput(
              value: albumName,
              labelText: '专辑名称'.tr,
              onSaved: (value) {
                albumName = value ?? '';
              },
            ),
            SizedBox(
              height: 30.w,
            ),
            renderInput(
              value: art,
              labelText: '艺人'.tr,
              onSaved: (value) {
                art = value ?? '';
              },
            ),
            SizedBox(
              height: 30.w,
            ),
            SizedBox(
              width: double.infinity,
              height: 80.w,
              child: TextButton(
                style: ButtonStyle(
                    backgroundColor: WidgetStatePropertyAll(
                        Get.theme.primaryColor.withValues(alpha: .1))),
                onPressed: () {
                  var validate = _formKey.currentState?.validate() ?? false;
                  if (!validate) {
                    return;
                  }
                  _formKey.currentState?.save();
                  onSave(name: name, albumName: albumName, art: art);
                  Get.back();
                },
                child: Text(
                  '确定'.tr,
                  style: TextStyle(fontSize: 26.sp),
                ),
              ),
            ),
            SizedBox(
              height: 30.w,
            ),
            SizedBox(
              width: double.infinity,
              height: 80.w,
              child: TextButton(
                style: ButtonStyle(
                    backgroundColor: WidgetStatePropertyAll(
                        Get.theme.primaryColor.withValues(alpha: .1))),
                onPressed: () {
                  Get.back();
                },
                child: Text(
                  '取消'.tr,
                  style: TextStyle(fontSize: 26.sp),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
