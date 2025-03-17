import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:media_kit/media_kit.dart';
import 'package:pms/bindings/export.dart';
import 'package:pms/common/lang.dart';
import 'package:pms/common/theme_config.dart';
import 'package:pms/pages/export.dart';
import 'package:sqflite/sqflite.dart';
import 'package:switch_orientation/switch_orientation.dart';
import 'package:media_player_plugin/export.dart';

initConfig() async {
  media_player_plugin_restart();

  String cachePath = await getDatabasesPath();
  Hive.init(cachePath);
  EasyLoading.instance.indicatorType = EasyLoadingIndicatorType.squareCircle;
  // CachedNetworkImageProvider.defaultCacheManager = CacheManager(Config(
  //   'pms_image_cache',
  //   repo: JsonCacheInfoRepository(path: '$cachePath/pms_image_cache.json'),
  // ));
  MediaKit.ensureInitialized();
  SwitchOrientation.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    // DeviceOrientation.portraitDown,
    // DeviceOrientation.landscapeLeft,
    // DeviceOrientation.landscapeRight,
  ]);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initConfig();
  SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.manual,
    overlays: [SystemUiOverlay.top],
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(720, 1280),
      builder: (_, child) {
        return GetMaterialApp(
          debugShowCheckedModeBanner: false,
          initialRoute: '/home',
          initialBinding: MainBinding(),
          theme: ThemeConfig.themes.first.light,
          themeMode: ThemeMode.light,
          translations: Messages(),
          locale: Get.deviceLocale,
          fallbackLocale: const Locale('zh', 'CN'),
          builder: EasyLoading.init(),
          getPages: [
            HomePage.page,
            AliyunPage.page,
            SettingPage.page,
            MusicAlbumPage.page,
            MusicPlayPage.page,
            NeteasePage.page,
            BiliPage.page,
            TaskPage.page,
            VideoAlbumPage.page,
            VideoFullPage.page,
            VideoCutPage.page,
            YoutubePage.page,
          ],
        );
      },
    );
  }
}
