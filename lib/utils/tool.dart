import 'dart:async';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:logger/logger.dart';
import 'package:pms/utils/chain.dart';
import 'package:sqflite/sqflite.dart';

var logger = Logger(printer: PrettyPrinter());

class Tool {
  static Map<String, String> parseCookie(String? cookie) {
    if (cookie == null) return {};
    Map<String, String> cookieMap = {};
    List<String> pairs = cookie.split(';');
    for (String pair in pairs) {
      List<String> keyValue = pair.trim().split('=');
      if (keyValue.length == 2) {
        cookieMap[keyValue[0]] = keyValue[1];
      }
    }
    return cookieMap;
  }

  static String mapToCookieString(Map<String, String?> cookieMap) {
    return cookieMap.entries
        .where((item) => item.value != null)
        .map(
          (entry) =>
              '${Uri.encodeComponent(entry.key)}=${Uri.encodeComponent(entry.value ?? '')}',
        )
        .join('; ');
  }

  static log(dynamic message) {
    logger.i(message);
  }

  static var appCachePath = "";
  static var appAssetsPath = "";
  static var coverStorePath = "";

  static initAssetPath() async {
    appCachePath = await getAppCachePath();
    appAssetsPath = await getAppAssetsPath();
    coverStorePath = await getCoverStorePath();
  }

  /// 获取应用缓存路径
  static Future<String> getAppCachePath() async {
    var doc = await getApplicationCacheDirectory();
    return doc.path;
  }

  /// 获取应用资源路径
static Future<String> getAppAssetsPath() async {
  final doc = await getApplicationDocumentsDirectory();
  return doc.path;
}

  /// 获取封面保存路径
  static Future<String> getCoverStorePath() async {
    var assetsPath = await getAppAssetsPath();
    var coverPath = '$assetsPath/cover';
    await Directory(coverPath).create(recursive: true);
    return coverPath;
  }

  static Future<File> saveAsset({
    required ResponseBody response,
    required String path,
    int start = 0,
  }) async {
    int lastIndex = path.lastIndexOf('/');
    var dir = path.substring(0, lastIndex);
    // var filename = path.substring(lastIndex + 1);
    await Directory(dir).create(recursive: true);

    File file = File(path);
    // var sink = await file.open(mode: FileMode.write);
    var completer = Completer<File>();

    response.stream.listen(
      (data) {
        file.writeAsBytesSync(data, mode: FileMode.append);
      },
      onDone: () async {
        completer.complete(file);
      },
      onError: (error) {
        completer.completeError(error);
      },
    );

    return completer.future;
  }

  static showConfirm({
    required String title,
    required String content,
    required Future<void> Function() onConfirm,
  }) {
    Get.dialog(
      AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () {
              Get.back();
            },
            child: Text("取消".tr),
          ),
          TextButton(
            onPressed: () async {
              await onConfirm();
              Get.back();
            },
            child: Text("确定".tr),
          ),
        ],
      ),
    );
  }

  static Future<T?> showMenuPosition<T>({
    required BuildContext context,
    required List<PopupMenuEntry<T>> items,
    Offset? offset,
  }) {
    final PopupMenuThemeData popupMenuTheme = PopupMenuTheme.of(context);
    final RenderBox button = context.findRenderObject()! as RenderBox;
    final overlay =
        Navigator.of(context).overlay!.context.findRenderObject()! as RenderBox;

    var offset0 = button.localToGlobal(
      offset ?? const Offset(0, 0),
      ancestor: overlay,
    );

    final RelativeRect position = RelativeRect.fromLTRB(
      offset0.dx,
      offset0.dy,
      button.size.width - offset0.dx,
      overlay.size.height - offset0.dy,
    );

    return showMenu(
      context: context,
      elevation: popupMenuTheme.elevation,
      shadowColor: popupMenuTheme.shadowColor,
      surfaceTintColor: popupMenuTheme.surfaceTintColor,
      items: items,
      position: position,
      shape: popupMenuTheme.shape,
      menuPadding: popupMenuTheme.menuPadding,
      color: popupMenuTheme.color,
    );
  }

  static Future<T?> showBottomSheet<T>(Widget bottomsheet) {
    var theme = Get.theme;

    var isDarkMode = theme.brightness == Brightness.dark;

    var barrierColor = isDarkMode ? Colors.white54 : Colors.black54;

    var background = isDarkMode ? Colors.black : Colors.white;

    return Get.bottomSheet(
      bottomsheet,
      barrierColor: barrierColor,
      backgroundColor: background,
      isScrollControlled: true,
    );
  }

  static Future<String> parseUrlAssetName({
    required String url,
    Map<String, dynamic>? params,
    Map<String, dynamic>? headers,
  }) async {
    var urlObj = Uri.parse(url);
    var path = urlObj.path;

    if (path.contains('.')) {
      return path.replaceAll('.data', '.mp3');
    }

    var chain = DioChain(
      headers: {
        "User-Agent":
            "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) aDrive/6.3.1 Chrome/112.0.5615.165 Electron/24.1.3.7 Safari/537.36",
        "x-canary": "client=Windows,app=adrive,version=v6.4.2",
        "sec-fetch-dest": "empty",
        "sec-fetch-mode": "no-cors",
        "sec-fetch-site": "none",
      },
    );

    List<String> names = [];

    try {
      var response = await chain
          .head(url)
          .query(params ?? {})
          .setMemoryCache(double.infinity)
          .setHeaders(headers ?? {});
      names = response.headers['content-disposition'] ?? [];
    } catch (e) {
      var response = await chain
          .get(url)
          .query(params ?? {})
          .setMemoryCache(double.infinity)
          .setHeaders(headers ?? {})
          .setRange(0, 1);
      names = response.headers['content-disposition'] ?? [];
    }

    if (names.isEmpty) {
      return '';
    }

    for (String value in names) {
      var urlencode = value
          .replaceAll(RegExp(r"attachment|;|filename|\*|=|UTF-8|''"), '')
          .trim();

      return Uri.decodeComponent(urlencode);
    }

    return '';
  }

  static Future<File> deleteAsset(String local) async {
    var file = File(local);
    var isExist = await file.exists();
    if (isExist) {
      await file.delete(recursive: true);
    }
    return file;
  }

  static Future<File> cacheImg({
    required String url,
    String? referer,
    String? cacheKey,
  }) async {
    var provider = CachedNetworkImageProvider(
      url,
      cacheKey: cacheKey,
      headers: referer == null ? null : {"referer": referer},
    );
    await precacheImage(provider, Get.context!);

    File? file;

    if (cacheKey != null) {
      var result = await CachedNetworkImageProvider.defaultCacheManager
          .getFileFromCache(cacheKey);
      file = result?.file;
    } 

    if(file==null)
     {
      var result =
          await CachedNetworkImageProvider.defaultCacheManager.getSingleFile(
        url,
        headers: referer == null ? {} : {"referer": referer},
      );
      file = result;
    }

    return file;
  }

  static bool isAudioFile(String filePath) {
    final audioExtensions = ['mp3', 'wav', 'm4a', 'ogg', 'flac', 'aac'];
    final fileExtension =
        filePath.split('.').last.toLowerCase(); // 判断文件扩展名是否在音频扩展名列表中
    return audioExtensions.contains(fileExtension);
  }

  static bool isVideoFile(String filePath) {
    final videoExtensions = ['mp4', 'avi', 'mkv', 'mov', 'flv', 'wmv', 'webm'];
    final fileExtension = filePath.split('.').last.toLowerCase();
    return videoExtensions.contains(fileExtension);
  }

  static String formatSize(int size) {
    if (size >= 1 << 30) {
      double sizeInGB = size / (1 << 30);
      return '${sizeInGB.toStringAsFixed(2)} GB';
    } else if (size >= 1 << 20) {
      double sizeInMB = size / (1 << 20);
      return '${sizeInMB.toStringAsFixed(2)} MB';
    } else if (size >= 1 << 10) {
      double sizeInKB = size / (1 << 10);
      return '${sizeInKB.toStringAsFixed(2)} KB';
    } else {
      return '$size B';
    }
  }

  static int getDirectorySize(Directory directory) {
    int size = 0;
    try {
      List<FileSystemEntity> entities = directory.listSync(recursive: true);
      for (FileSystemEntity entity in entities) {
        if (entity is File) {
          size += entity.lengthSync();
        }
      }
    } catch (e) {
      return 0;
    }
    return size;
  }
}
