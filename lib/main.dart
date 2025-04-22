import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:media_player_plugin/media_player_plugin.dart';
import 'package:pms/bindings/export.dart';
import 'package:pms/common/lang.dart';
import 'package:pms/common/theme_config.dart';
import 'package:pms/pages/export.dart';
import 'package:pms/utils/tool.dart';
// import 'package:pms/utils/cache_file_system.dart';
import 'package:sqflite/sqflite.dart';
import 'package:switch_orientation/switch_orientation.dart';

initConfig() async {
  EasyLoading.instance.indicatorType = EasyLoadingIndicatorType.squareCircle;
  SwitchOrientation.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    // DeviceOrientation.portraitDown,
    // DeviceOrientation.landscapeLeft,
    // DeviceOrientation.landscapeRight,
  ]);

  String cachePath = await getDatabasesPath();
  Hive.init("$cachePath/hive");
  await Tool.initAssetPath();

  // CachedNetworkImageProvider.defaultCacheManager = CacheManager(Config(
  //   'pms_image_cache',
  //   repo: JsonCacheInfoRepository(path: '$cachePath/hive/pms_image_cache.json'),
  //   fileSystem: IOFileSystemEx("pms_image_cache"),
  //   stalePeriod: const Duration(days: 30),
  // ));
}

void main() async {
  var widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  await initConfig();
  SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.manual,
    overlays: [SystemUiOverlay.top],
  );
  runApp(const MyApp());
  MediaPlayerPlugin.restart();
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<StatefulWidget> createState() {
    return _MyAppState();
  }
}

class _MyAppState extends State {
  @override
  void initState() {
    super.initState();
    FlutterNativeSplash.remove();
  }

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
            AudioPlayerTest.page,
          ],
        );
      },
    );
  }
}
