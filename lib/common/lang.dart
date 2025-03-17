import 'package:get/get.dart';
import 'package:pms/common/lang/en_US.dart';
import 'package:pms/common/lang/zh_CN.dart';
import 'package:pms/common/lang/zh_Hans.dart';

class Messages extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
        'zh_CN': zhCN,
        'zh_Hans': zhHans,
        'en_US': enUS,
      };
}
