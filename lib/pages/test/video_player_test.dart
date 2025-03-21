import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

class VideoPlayerTest extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _VideoPlayerTest();
  }

  static String path = '/video_player_test';

  static to() {
    return Get.toNamed(path);
  }

  static GetPage page = GetPage(
    name: path,
    page: () {
      return VideoPlayerTest();
    },
    transition: Transition.rightToLeft,
  );
}

class _VideoPlayerTest extends State {
  late final player = Player(
    configuration: PlayerConfiguration(logLevel: MPVLogLevel.error),
  );
  late final controller = VideoController(player);
  final String baseUrl = "http://192.168.110.218:5500";

  @override
  void initState() {
    super.initState();
    player.open(
      Media(
        '$baseUrl/test.mpd',
        httpHeaders: {"referrer": "https://www.bilibili.com/"},
      ),
    );
    player.play();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("video player test")),
      body: Center(
        child: SizedBox(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.width * 9.0 / 16.0,
          child: Video(controller: controller),
        ),
      ),
    );
  }
}
