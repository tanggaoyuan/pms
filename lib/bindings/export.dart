library binding;

import 'package:get/get.dart';
import 'setting.dart';
import 'audio.dart';
import 'task.dart';

export './setting.dart';
export './audio.dart';
export './task.dart';

class MainBinding implements Bindings {
  @override
  void dependencies() {
    Get.put<AudioController>(AudioController(), permanent: true);
    Get.put<TaskController>(TaskController(), permanent: true);
    Get.put<SettingController>(SettingController(), permanent: true);
  }
}
