import 'dart:async';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';
import 'package:media_player_plugin/media_audio_player.dart';
import 'package:pms/db/export.dart';
import 'package:pms/utils/export.dart';

enum PlayMode { order, one, random }

class AudioController extends GetxController {
  final List<StreamSubscription> _subscriptions = [];

  RxList<MediaDbModel> songs = RxList<MediaDbModel>([]);

  List<MediaDbModel> _temps = [];

  late Timer _timerRef;

  var player = MediaAudioPlayer();
  var current = (-1).obs;
  var position = const Duration(milliseconds: 0).obs;
  var cachePosition = const Duration(milliseconds: 0).obs;
  var duration = const Duration(milliseconds: 0).obs;
  var playing = false.obs;
  var isBuffering = false.obs;
  var playMode = PlayMode.order.obs;
  var albumId = (-1).obs;
  var showLyric = false.obs;
  var enableTimeMode = false.obs;
  var enableHeadsetMode = false.obs;
  var time = 0.obs;

  init() async {
    await player.init();
    await player.enablePlayback();
    player.registerPlayBackEvent(
      onPlayBackPrevious: prev,
      onPlayBackNext: next,
    );

    _subscriptions.add(
      player.playStateStream!.listen((event) {
        playing.value = event.isPlaying;
        isBuffering.value = event.isBuffering;
        if (event.isPlayCompleted) {
          if (playMode.value == PlayMode.one) {
            play(current.value);
          } else {
            next();
          }
        }
      }),
    );

    _subscriptions.add(
      player.durationStream!.listen((event) {
        cachePosition.value = Duration(seconds: event.cacheDuration.round());
        position.value = Duration(seconds: event.position.round());
        duration.value = Duration(seconds: event.duration.round());
      }),
    );

    _timerRef = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!enableTimeMode.value) {
        return;
      }
      time.value--;
      if (time.value == 0) {
        enableTimeMode.value = false;
        player.pause();
      }
    });
  }

  @override
  void onInit() {
    super.onInit();
    init();
  }

  MediaDbModel? get currentSong {
    if (songs.isEmpty) {
      return null;
    }
    return songs[current.value];
  }

  play(int index, [int? albumId]) async {
    current.value = index;

    if (albumId != null) {
      this.albumId.value = albumId;
    }

    var song = songs[index];
    var urls = await song.getPlayUrl();

    print("urls ${urls}");

    var url = urls.first.isNotEmpty ? urls.first : urls.last;

    String artUri = "";

    if (song.cover.startsWith('http')) {
      var oc = await CachedNetworkImageProvider.defaultCacheManager
          .getFileFromCache(song.cacheKey);
      if (oc != null && oc.file.existsSync()) {
        artUri = oc.file.path;
      } else {
        artUri = song.cover;
      }
    } else if (song.cover.startsWith('assets/')) {
      var savePath = await Tool.getCoverStorePath();

      final fileName = song.cover.split('/').last;
      final filePath = '$savePath/$fileName';
      File file = File(filePath);

      if (!file.existsSync()) {
        final byteData = await rootBundle.load(song.cover);
        var imageBytes = byteData.buffer.asUint8List();
        await file.writeAsBytes(imageBytes);
        await file.exists();
      }

      artUri = 'file://$filePath';
    } else {
      artUri = 'file://${song.cover}';
    }

    var headers = {
      "referer": song.extra.referer,
      "origin": song.extra.referer,
      "User-Agent":
          'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36 Edg/131.0.0.0',
    };
    await player.setUrl(url: url, urlHeader: headers, cover: artUri);
    await player.prepare();
    await player.play();
  }

  next() {
    if (current.value == songs.length - 1) {
      play(0);
    } else {
      play(current.value + 1);
    }
  }

  prev() {
    if (current.value == 0) {
      play(songs.length - 1);
    } else {
      play(current.value - 1);
    }
  }

  remove(int index) {
    var song = songs.removeAt(index);
    _temps.remove(song);

    if (songs.isEmpty) {
      return;
    }

    if (current.value == index) {
      if (songs.length - 1 > index) {
        play(index);
      } else {
        play(songs.length - 1);
      }
      return;
    }

    if (current.value > index) {
      current.value--;
    }
  }

  setPlayList(List<MediaDbModel> songs) {
    this.songs.value = _temps = [...songs];
  }

  togglePlayMode() {
    var index = PlayMode.values.indexOf(playMode.value);
    playMode.value = PlayMode.values[(index + 1) % PlayMode.values.length];

    if (playMode.value == PlayMode.one) {
      return;
    }

    var song = currentSong;
    if (playMode.value == PlayMode.order) {
      songs.value = _temps;
    }
    if (playMode.value == PlayMode.random) {
      var temps = [..._temps];
      temps.shuffle();
      songs.value = temps;
    }
    current.value = songs.indexOf(song);
  }

  toggleTimeMode() {
    enableTimeMode.value = !enableTimeMode.value;
  }

  @override
  void dispose() {
    super.dispose();
    for (var item in _subscriptions) {
      item.cancel();
    }
    _timerRef.cancel();
    player.destroy();
  }
}
