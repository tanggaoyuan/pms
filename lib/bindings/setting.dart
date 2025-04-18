import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:pms/common/theme_config.dart';
import 'package:pms/utils/export.dart';

class SettingController extends GetxController {
  final List<ThemeConfig> themes = ThemeConfig.themes;
  final storePromise = Hive.openBox<Map>("app_config");

  final List<Locale> locales = [
    const Locale('zh', 'CN'),
    const Locale('zh', 'Hans'),
    const Locale('en', 'US'),
  ];

  @override
  void onInit() {
    super.onInit();
    init();
  }

  init() async {
    final store = await storePromise;
    Map config = store.get('config') ?? {};

    if (config['locale'] is int) {
      _localIndex.value = config['locale'] as int;
      Get.updateLocale(locales[localIndex]);
    } else {
      for (var i = 0; i < locales.length; i++) {
        if (locales[i].toString() == Get.deviceLocale.toString()) {
          _localIndex.value = i;
          Get.updateLocale(locales[i]);
          config['locale'] = i;
          store.put('config', config);
        }
      }
    }
    if (config['theme'] is int) {
      _themeIndex.value = config['theme'] as int;
    }
  }

  final _themeIndex = 0.obs;
  final _themeMode = ThemeMode.light.obs;
  final _localIndex = 0.obs;

  int get themeIndex {
    return _themeIndex.toInt();
  }

  int get localIndex {
    return _localIndex.toInt();
  }

  ThemeMode get themeMode {
    return _themeMode.value;
  }

  bool get isDarkMode {
    return themeMode == ThemeMode.dark;
  }

  bool get isLightMode {
    return themeMode == ThemeMode.light;
  }

  ThemeData get lightTheme {
    return themes[themeIndex].light;
  }

  ThemeData get darkTheme {
    return themes[themeIndex].dark;
  }

  ThemeData get theme {
    return isDarkMode ? darkTheme : lightTheme;
  }

  Color get background {
    return theme.scaffoldBackgroundColor;
  }

  void selectTheme(int index) async {
    _themeIndex.value = index;
    Get.changeTheme(theme);
    final store = await storePromise;
    Map config = store.get('config') ?? {};
    config['theme'] = index;
    store.put('config', config);
  }

  void selectLocal(int index) async {
    _localIndex.value = index;
    Get.updateLocale(locales[localIndex]);
    final store = await storePromise;
    Map config = store.get('config') ?? {};
    config['locale'] = index;
    store.put('config', config);
  }

  void toggleThemeMode() {
    _themeMode.value =
        _themeMode.value == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    _updateToastStyle();
    Get.changeTheme(theme);
  }

  _updateToastStyle() {
    EasyLoading.instance.loadingStyle = themeMode == ThemeMode.dark
        ? EasyLoadingStyle.light
        : EasyLoadingStyle.dark;
  }
}
