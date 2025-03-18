import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:media_player_plugin/equalizer_view.dart';
import 'package:media_player_plugin/fft_viwe.dart';
import 'package:media_player_plugin/media_audio_player.dart';




class AudioPlayerTest extends StatefulWidget {
  const AudioPlayerTest({super.key});

  @override
  _AudioPlayerTestState createState() => _AudioPlayerTestState();

    static String path = '/audio_player_test';

  static to() {
    return Get.toNamed(path);
  }

  static GetPage page = GetPage(
    name: path,
    page: () {
      return AudioPlayerTest();
    },
    transition: Transition.rightToLeft,
  );
}

const frequencys = [
  31.0,
  62.0,
  125.0,
  250.0,
  500.0,
  1000.0,
  2000.0,
  4000.0,
  8000.0,
  16000.0,
];

class _AudioPlayerTestState extends State<AudioPlayerTest> {
  // 设置均衡器频段
  final controller = MediaAudioPlayer(frequencys: frequencys);

  int? id = 0;
  int key = 0;

  final String baseUrl = "http://192.168.110.218:5500";

  List<Map> songs = [];

  int current = 0;
  Duration position = Duration.zero;
  Duration duration = Duration.zero;
  Duration bufferd = Duration.zero;
  List<double> fftOptions = [2, 1];

  init() async {
    await controller.init();

    controller.playStateStream!.listen((data){
      print("isBuffering->${data.isBuffering}  isPlayCompleted->${data.isPlayCompleted}  isPlaying->${data.isPlaying}");
    });

    controller.registerPlayBackEvent(
      onPlayBackPrevious: () async {
        current--;
        if (current < 0) {
          current = songs.length - 1;
        }
        setState(() {});
        await setPlayIndex(current);
        await controller.play();
      },
      onPlayBackNext: () async {
        current++;
        if (current == songs.length) {
          current = 0;
        }
        setState(() {});
        await setPlayIndex(current);
        await controller.play();
      }
    );

    controller.durationStream!.listen((data) {
      setState(() {
        position = Duration(milliseconds: (data.position * 1000).round());
        duration = Duration(milliseconds: (data.duration * 1000).round());
        bufferd = Duration(milliseconds: (data.cacheDuration * 1000).round());
      });
    });

    songs = [
      {
        "url": '$baseUrl/huahai.flac',
        "title": '花海',
        "artist": "周杰伦",
        "cover": "$baseUrl/1.png",
      },
      {"url": '$baseUrl/Ground.mp3'},
    ];

    setPlayIndex(current);

    setState(() {});
  }

  setPlayIndex(int index) async {
    Map song = songs[index];
    await controller.setUrl(
      url: song["url"],
      title: song["title"],
      artist: song["artist"],
      cover: song["cover"]
    );
    await controller.prepare();
  }

  @override
  void initState() {
    super.initState();
    init();
  }

  @override
  dispose() {
    super.dispose();
    controller.destroy();
  }

  @override
  Widget build(BuildContext context) {
    if (songs.isEmpty) {
      return Scaffold(body: Center(child: Text("加载中")));
    }

    var style = TextButton.styleFrom(
      padding: EdgeInsets.all(6), // 移除内边距
      minimumSize: Size.zero, // 允许按钮更小
      tapTargetSize: MaterialTapTargetSize.shrinkWrap, // 缩小点击区域
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6), // 添加圆角
      ),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Audio Play')),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 240, 239, 239),
              borderRadius: BorderRadius.circular(10),
            ),
            margin: EdgeInsets.all(10),
            padding: EdgeInsets.all(10),
            child: Text(songs[current]["url"]),
          ),
          Padding(
            padding: EdgeInsets.all(10),
            child: ProgressBar(
              progress: position,
              buffered: bufferd,
              total: duration,
              onSeek: (value) {
                controller.seek(value.inSeconds.toDouble());
                position = value;
                setState(() {});
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.all(10),
            child: Row(
              children: [
                ElevatedButton(
                  onPressed: () async {
                    current = (current + 1) % songs.length;
                    setState(() {});
                    await setPlayIndex(current);
                    await controller.play();
                  },
                  style: style,
                  child: Text("切换"),
                ),
                SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () {
                    controller.play();
                  },
                  style: style,
                  child: const Text('播放'),
                ),
                SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () {
                    controller.pause();
                  },
                  style: style,
                  child: const Text('暂停'),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(10),
            child: Row(
              children: [
                ElevatedButton(
                  onPressed: () async {
                    var bands = await controller.getEqBands();
                    EqualizerView.show(
                      context: context,
                      bands: bands,
                      height: 300,
                      enableEq: controller.isEqActive,
                      onEqSwitchChanged: (value) {
                        if (value) {
                          controller.enableEq();
                        } else {
                          controller.disableEq();
                        }
                      },
                      onChanged: (index, value) {
                        controller.updateBand(index, gain: value);
                      },
                      onReset: () {
                        for (var i = 0; i < bands.length; i++) {
                          controller.updateBand(i, gain: 0);
                        }
                      },
                    );
                  },
                  style: style,
                  child: const Text("打开均衡器"),
                ),
                SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () async {
                    var gains = [6, 4, 6, 2, 0, 0, 0, 0, 0, 0];
                    for (var i = 0; i < gains.length; i++) {
                      controller.updateBand(
                        i,
                        gain: gains[i].toDouble(),
                        bypass: false,
                      );
                    }
                  },
                  style: style,
                  child: const Text("低音"),
                ),
                SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () async {
                    var gains = [9, 9, 9, 5, 0, 4, 11, 11, 11, 11];
                    for (var i = 0; i < gains.length; i++) {
                      controller.updateBand(
                        i,
                        gain: gains[i].toDouble(),
                        bypass: false,
                      );
                    }
                  },
                  style: style,
                  child: const Text("高音"),
                ),
                SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () async {
                    var gains = [10, 10, 5, -5, -3, 2, 8, 10, 11, 12];
                    for (var i = 0; i < gains.length; i++) {
                      controller.updateBand(
                        i,
                        gain: gains[i].toDouble(),
                        bypass: false,
                      );
                    }
                  },
                  style: style,
                  child: const Text("强劲"),
                ),
                SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () async {
                    var gains = [2, 0, -2, -4, -2, 2, 5, 7, 8, 9];
                    for (var i = 0; i < gains.length; i++) {
                      controller.updateBand(
                        i,
                        gain: gains[i].toDouble(),
                        bypass: false,
                      );
                    }
                  },
                  style: style,
                  child: const Text("轻柔"),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(10),
            child: Row(
              children: [
                ElevatedButton(
                  onPressed: () {
                    controller.enablePlayback();
                  },
                  style: style,
                  child: const Text("开启播放通知"),
                ),
                SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () {
                    controller.disablePlayback();
                  },
                  style: style,
                  child: const Text("关闭播放通知"),
                ),
              ],
            ),
          ),
          FFtView(
            controller: controller,
            width: 380,
            indicatorWidth: fftOptions[0],
            indicatorHeight: 60,
            spaceWidth: fftOptions[1],
          ),
          Padding(
            padding: EdgeInsets.all(10),
            child: Row(
              children: [
                ElevatedButton(
                  onPressed: () {
                    controller.enableFFT();
                  },
                  style: style,
                  child: const Text("开启FFT"),
                ),
                SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () {
                    controller.disableFFT();
                  },
                  style: style,
                  child: const Text("关闭FFT"),
                ),
                SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      fftOptions = [2, 1];
                    });
                  },
                  style: style,
                  child: const Text("正常fft视图"),
                ),
                SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      fftOptions = [1, 0];
                    });
                  },
                  style: style,
                  child: const Text("密集fft视图"),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
