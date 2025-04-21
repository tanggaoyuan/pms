
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:pms/pages/export.dart';
import 'package:pms/pages/home/components/music.dart';
import 'components/video.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  static String path = '/home';

  static GetPage page = GetPage(
    name: path,
    page: () {
      return const HomePage();
    },
    binding: HomeBinding(),
    transition: Transition.rightToLeft,
  );

  @override
  State<StatefulWidget> createState() {
    return _HomeStatePage();
  }
}

class _HomeStatePage extends State<HomePage> with WidgetsBindingObserver {
  late PageController controller;

  int activePath = 0;

  final List<Map> tabs = [
    {"title": '音乐'.tr, "icon": const FaIcon(FontAwesomeIcons.radio)},
    {"title": '视频'.tr, "icon": const FaIcon(FontAwesomeIcons.youtube)},
  ];

  @override
  void initState() {
    super.initState();
    controller = PageController();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    super.dispose();
    controller.dispose();
    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    super.didChangeAppLifecycleState(state);
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: [SystemUiOverlay.top],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(tabs[activePath]['title']),
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () async {
            await SettingPage.to();
            Get.find<HomeController>().initMuiceAlbums();
          },
        ),
        actions: [
          IconButton(
            onPressed: () {
              TaskPage.to();
            },
            icon: const FaIcon(FontAwesomeIcons.download),
          ),
          // IconButton(
          //   onPressed: () {
          //     YoutubePage.to();
          //   },
          //   icon: const FaIcon(FontAwesomeIcons.youtube),
          // ),
        ],
      ),
      body: PageView(
        controller: controller,
        children: const [MusicComp(), VideoComp()],
        onPageChanged: (value) {
          setState(() {
            activePath = value;
          });
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        selectedFontSize: 22.sp,
        unselectedFontSize: 22.sp,
        iconSize: 40.w,
        currentIndex: activePath.toInt(), // 设置当前选中的索引
        onTap: (index) {
          if (activePath.toInt() == index) {
            return;
          }
          controller.animateToPage(
            index,
            duration: const Duration(milliseconds: 500),
            curve: Curves.ease,
          );
          setState(() {
            activePath = index;
          });
        },
        items: tabs.map((item) {
          return BottomNavigationBarItem(
            icon: item['icon'],
            label: item['title'],
          );
        }).toList(),
      ),
    );
  }
}
