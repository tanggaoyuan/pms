// ignore_for_file: must_be_immutable

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

class AlbumOperationComp extends StatelessWidget {
  final Function(String value) onSave;
  final _formKey = GlobalKey<FormState>();

  late String name;

  /// 专辑创建弹窗
  AlbumOperationComp({super.key, required this.onSave, this.name = ''});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 380.w,
      width: double.infinity,
      padding: EdgeInsets.all(30.w),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            Text(
              '创建专辑'.tr,
              style: TextStyle(fontSize: 30.sp),
            ),
            SizedBox(
              height: 20.w,
            ),
            TextFormField(
              initialValue: name,
              autofocus: true,
              decoration: InputDecoration(
                fillColor: Get.theme.primaryColor.withValues(alpha: .1),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20.w),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                      color: Get.theme.primaryColorLight.withValues(alpha: .1),
                      width: 1.w),
                  borderRadius: BorderRadius.circular(20.w),
                ),
                filled: true,
                labelText: '专辑名称'.tr,
                contentPadding:
                    EdgeInsets.symmetric(vertical: 10.w, horizontal: 20.w),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '请输入'.tr;
                }
                return null;
              },
              onSaved: (value) {
                name = value ?? '';
              },
            ),
            SizedBox(
              height: 20.w,
            ),
            SizedBox(
              width: double.infinity,
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
                  onSave(name);
                },
                child: Text(
                  '确定'.tr,
                  style: TextStyle(fontSize: 30.sp),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
