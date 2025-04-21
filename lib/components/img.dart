import 'dart:async';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:pms/bindings/audio.dart';
import 'package:pms/utils/tool.dart';

Map<String, IconData> awesomeIcons = {
  ImgCompIcons.compactDisc: FontAwesomeIcons.compactDisc,
  ImgCompIcons.album: FontAwesomeIcons.icons,
  ImgCompIcons.play: FontAwesomeIcons.play,
  ImgCompIcons.pause: FontAwesomeIcons.pause,
  ImgCompIcons.bars: FontAwesomeIcons.bars,
};

class ImgCompIcons {
  static getAssetImagePath(String filename) {
    return 'assets/images/$filename';
  }

  static String play = FontAwesomeIcons.play.toString();
  static String pause = FontAwesomeIcons.pause.toString();

  static String bars = FontAwesomeIcons.bars.toString();

  /// 唱片图标
  static String compactDisc = FontAwesomeIcons.compactDisc.toString();

  /// 专辑图标
  static String album = FontAwesomeIcons.icons.toString();

  /// 本地音乐图标
  static String localMusic = getAssetImagePath('music_file.png');

  /// 本地视频图标
  static String localVideo = getAssetImagePath('video_file.png');

  /// 添加专辑图标
  static String albumPlus = getAssetImagePath('add_file.png');

  /// 文件导入图标
  static String importFile = getAssetImagePath('import_file.png');

  /// 阿里云图标
  static String aliyun = getAssetImagePath('aliyun.png');

  /// 哔哩哔哩图标
  static String bili = getAssetImagePath('bili.png');

  /// 网易云音乐图标
  static String netease = getAssetImagePath('wanyii.png');

  /// 阿里文件夹图标
  static String aliDir = getAssetImagePath('dir.png');

  /// 阿里文件图标
  static String aliFile = getAssetImagePath('file.png');

  /// 阿里视频图标
  static String aliVideo = getAssetImagePath('video.png');

  /// 阿里音频图标
  static String aliAudio = getAssetImagePath('audio.png');

  /// 阿里文档图标
  static String aliZip = getAssetImagePath('zip.png');

  /// 默认封面
  static String cover = getAssetImagePath('cover.jpg');

  /// 主图
  static String mainCover = getAssetImagePath('main_cover.jpg');

  /// 顺序播放
  static String orderPlay = getAssetImagePath('order_play.png');

  /// 单曲循环
  static String singleTunePlay = getAssetImagePath('single_tune_play.png');

  /// 随机播放
  static String randomPlay = getAssetImagePath('random_play.png');
}

class ImgComp extends StatefulWidget {
  final String source;
  final double? width;
  final double? height;
  final Color? color;
  final double? radius;
  final Widget Function(Image image, ImageInfo info)? builder;
  final BoxFit? fit;
  final String? referer;
  final String? cacheKey;

  /// 图片处理类
  const ImgComp({
    super.key,
    required this.source,
    this.width,
    this.height,
    this.color,
    this.radius,
    this.builder,
    this.fit,
    this.referer,
    this.cacheKey,
  });

  @override
  State<StatefulWidget> createState() {
    return _ImgCompState();
  }

  static Future<ImageInfo> getImageInfo(String url, {Map<String, String>? headers, String? cacheKey}) {
    var completer = Completer<ImageInfo>();
    try {
      const config = ImageConfiguration();
      var view = url.startsWith('http')
          ? Image(
              image: CachedNetworkImageProvider(url, headers: headers, cacheKey: cacheKey),
            )
          : url.startsWith('assets/')
              ? Image.asset(url)
              : Image.file(File(url));
      var listener = view.image.resolve(config);
      var hander = ImageStreamListener(
        (image, synchronousCall) {
          if (completer.isCompleted) {
            return;
          }
          completer.complete(image);
        },
        onError: (exception, stackTrace) {
          if (completer.isCompleted) {
            return;
          }
          completer.completeError('图片加载失败'.tr);
        },
      );
      listener.addListener(hander);
      completer.future.whenComplete(() {
        listener.removeListener(hander);
      });
    } catch (e) {
      completer.completeError(e);
    }
    return completer.future;
  }
}

class _ImgCompState extends State<ImgComp> {
  ImageInfo? info;

  @override
  void initState() {
    super.initState();
    if (widget.builder != null) {
      var referer = widget.referer;

      ImgComp.getImageInfo(widget.source, headers: referer != null ? {'referer': referer} : null).then((result) {
        setState(() {
          info = result;
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    var source = widget.source;
    var width = widget.width;
    var height = widget.height;
    var color = widget.color;
    var radius = widget.radius;
    var referer = widget.referer;

    Widget img;

    if (awesomeIcons[source] != null) {
      img = FaIcon(
        awesomeIcons[source],
        size: width,
        color: color,
      );
    } else if (source.startsWith('http')) {
      Map<String, String>? headers;

      if (referer is String) {
        headers = {"referer": referer};
      }

      if (referer == 'no-referrer') {
        headers = {'Referrer-Policy': 'no-referrer'};
      }

      img = Image(
        image: CachedNetworkImageProvider(
          source,
          headers: headers,
          cacheKey: widget.cacheKey,
        ),
        width: width,
        height: height ?? width,
        color: color,
        fit: widget.fit,
      );
    } else if (source.startsWith('/')) {
       img = Image.file(
        File("${Tool.coverStorePath}$source"),
        color: color,
        height: height ?? width,
        width: width,
        fit: widget.fit,
      );
    } else {
      img = Image.asset(
        source,
        color: color,
        height: height ?? width,
        width: width,
        fit: widget.fit,
      );
    }

    if (widget.builder != null && info != null) {
      img = widget.builder!(img as Image, info!);
    }

    if (radius != null) {
      img = ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: img,
      );
    }

    return img;
  }
}
