import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:media_player_plugin/media_audio_player.dart';
import 'package:pms/db/export.dart';

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

  final storePromise = Hive.openBox('media');

  init() async {
    await player.init();

    final store = await storePromise;
    List list = store.get("songs") ?? [];

    songs.value = _temps = list.map((item) {
      return MediaDbModel.fromMap(item);
    }).toList();

    var playModeIndex = store.get("playModeIndex") ?? 0;

    playMode.value = PlayMode.values[playModeIndex];

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

    if (songs.isNotEmpty) {
      var index = store.get("current") ?? 0;
      await play(index);
      await player.pause();
    }

    player.enablePlayback();

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
    if (songs.isEmpty ||
        current.value == -1 ||
        songs.length - 1 < current.value) {
      return MediaDbModel(
        name: "暂无播放数据".tr,
        albumName: "未知",
        platform: MediaPlatformType.local,
        type: MediaTagType.action,
      );
    }
    return songs[current.value];
  }

  play(int index, [int? albumId]) async {
    if (albumId != null) {
      this.albumId.value = albumId;
    }

    var song = songs[index];
    var urls = await song.getPlayUrl();

    var url = urls.first.isNotEmpty ? urls.first : urls.last;

    String artUri = "";

    if (song.cover.startsWith('http')) {
      var oc = await CachedNetworkImageProvider.defaultCacheManager
          .getFileFromCache(song.cacheKey);
      if (oc != null && oc.file.existsSync()) {
        artUri = 'file://${oc.file.path}';
      } else {
        artUri = song.cover;
      }
    } else {
      artUri = 'file://${song.cover}';
    }

    var headers = {
      "referer": song.extra.referer,
      "origin": song.extra.referer,
      "User-Agent":
          'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36 Edg/131.0.0.0',
    };
    await player.setUrl(
      url: url,
      urlHeader: headers,
      cover: artUri,
      title: song.name,
      artist: song.artist,
    );
    await player.prepare();
    await player.play();
    current.value = index;

    final store = await storePromise;
    await store.put("current", index);
  }

  next() {
    if (songs.isEmpty) {
      EasyLoading.showToast("暂无播放数据".tr);
      return;
    }

    if (current.value == songs.length - 1) {
      play(0);
    } else {
      play(current.value + 1);
    }
  }

  prev() {
    if (songs.isEmpty) {
      EasyLoading.showToast("暂无播放数据".tr);
      return;
    }
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

  setPlayList(List<MediaDbModel> songs) async {
    var store = await storePromise;
    this.songs.value = _temps = [...songs];
    store.put("songs", this.songs.map((item) => item.toMap()).toList());
  }

  togglePlayMode() async {
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

    final store = await storePromise;
    store.put("playModeIndex", PlayMode.values.indexOf(playMode.value));
  }

  toggleTimeMode() {
    enableTimeMode.value = !enableTimeMode.value;
  }

  @override
  void dispose() {
    super.dispose();
    // for (var item in _subscriptions) {
    //   item.cancel();
    // }
    _timerRef.cancel();
    player.destroy();
  }
}
