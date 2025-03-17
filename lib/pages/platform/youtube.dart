import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:get/route_manager.dart';
import 'package:pms/bindings/audio.dart';
import 'package:pms/db/export.dart';
import 'package:pms/utils/export.dart';
import 'package:webview_cookie_manager_plus/webview_cookie_manager_plus.dart';
import 'package:webview_flutter/webview_flutter.dart';

class YoutubeVideoFormat {
  late String mimeType;
  late String quality;
  late String qualityLabel;
  late String url;
  late int width;
  late int fps;
  late int contentLength;
  late int bitrate;
  late int averageBitrate;
  late int itag;
  late Map params = {};

  YoutubeVideoFormat({
    required this.itag,
    required this.mimeType,
    required this.quality,
    required this.qualityLabel,
    required this.url,
    required this.width,
    required this.fps,
    required this.contentLength,
    required this.bitrate,
    required this.averageBitrate,
  });

  updateParams(Map params) {
    this.params = params;
  }

  String get ext {
    if (mimeType.contains('mp4a')) {
      return 'm4a';
    }
    return mimeType.split(';').first.split('/').last;
  }

  String get ei {
    return Uri.parse(url).queryParameters['ei'] ?? '';
  }

  StreamController<List<int>> download(
    Function(int loaded, int total) onProgress,
  ) {
    final passThrough = StreamController<List<int>>(
      onCancel: () {
        // 处理取消逻辑
      },
    );

    var dio = Dio();
    dio.httpClientAdapter = IOHttpClientAdapter(
      createHttpClient: () {
        final client = HttpClient();
        client.findProxy = (uri) {
          return 'PROXY 10.0.2.2:7890';
        };
        client.badCertificateCallback =
            (X509Certificate cert, String host, int port) => true;
        return client;
      },
    );

    const chunkSize = 10 * 1024 * 1024;
    var start = 0;
    int end = start + chunkSize;

    Future<void> getNextChunk() async {
      if (end >= contentLength) end = contentLength;

      var response = await dio.get<ResponseBody>(
        effectiveUrl,
        options: Options(
          headers: {
            "Range": 'bytes=$start-$end',
            // TODO
          },
          responseType: ResponseType.stream,
        ),
      );

      response.data!.stream.listen(
        (chunk) {
          passThrough.add(chunk);
        },
        onDone: () {
          onProgress(end, contentLength);
          if (end != contentLength) {
            start = end + 1;
            end += chunkSize;
            getNextChunk();
          } else {
            passThrough.close();
          }
        },
        onError: (error) {
          passThrough.close();
        },
      );
    }

    getNextChunk();

    return passThrough;
  }

  String get effectiveUrl {
    if (params['n'] == null) {
      return '';
    }
    Tool.log(url);
    Uri uri = Uri.parse(url);
    Map<String, String> queryParams = Map<String, String>.from(
      uri.queryParameters,
    );
    queryParams['n'] = params['n'];
    return uri.replace(queryParameters: queryParams).toString();
  }

  bool get isVideo {
    return mimeType.contains('video');
  }

  bool get isAudio {
    return mimeType.contains('audio');
  }

  bool get isLive {
    return RegExp(r'\bsource[/=]yt_live_broadcast\b').hasMatch(url);
  }

  bool get isHLS {
    return RegExp(r'\/manifest\/hls_(variant|playlist)\/').hasMatch(url);
  }

  bool get isDash {
    return RegExp(r'\/manifest\/dash\/').hasMatch(url);
  }

  static YoutubeVideoFormat fromMap(Map json) {
    return YoutubeVideoFormat(
      mimeType: json['mimeType'] ?? '',
      quality: json['quality'] ?? '',
      qualityLabel: json['qualityLabel'] ?? '',
      url: json['url'] ?? '',
      width: json['width'] ?? 0,
      fps: json['fps'] ?? 0,
      contentLength: int.parse(json['contentLength'] ?? '0'),
      bitrate: json['bitrate'] ?? 0,
      averageBitrate: json['averageBitrate'],
      itag: json['itag'] ?? 0,
    );
  }

  Map toMap() {
    return {
      'mimeType': mimeType,
      'quality': quality,
      'qualityLabel': qualityLabel,
      'url': url,
      'width': width,
      'fps': fps,
      'contentLength': contentLength,
      'bitrate': bitrate,
      'averageBitrate': averageBitrate,
      'itag': itag,
      'effectiveUrl': effectiveUrl,
    };
  }
}

class YoutubeVideoInfo {
  late String title;
  late String cover;
  late String videoId;
  late String author;
  late String shortDescription;
  late List<YoutubeVideoFormat> formats;

  updateParams(Map params) {
    for (var item in formats) {
      item.updateParams(params);
    }
  }

  String get ei {
    return formats.first.ei;
  }

  String get mobileLink {
    return 'https://m.youtube.com/watch?v=$videoId';
  }

  String get pcLink {
    return 'https://www.youtube.com/watch?v=$videoId';
  }

  YoutubeVideoInfo({
    required this.title,
    required this.cover,
    required this.videoId,
    required this.shortDescription,
    required this.formats,
    required this.author,
  });

  static YoutubeVideoInfo fromMap(Map json) {
    var map = FormatMap(json);
    var thumbnails = map
        .getList(['videoDetails', 'thumbnail', 'thumbnails'])
        .cast<Map>()
        .map((e) => e['url'] ?? '');
    var adaptiveFormats =
        map.getList(['streamingData', 'adaptiveFormats']).cast<Map>();
    return YoutubeVideoInfo(
      title: map.getString(['videoDetails', 'title']),
      cover: thumbnails.last,
      videoId: map.getString(['videoDetails', 'videoId']),
      shortDescription: map.getString(['videoDetails', 'shortDescription']),
      formats:
          adaptiveFormats.map((e) => YoutubeVideoFormat.fromMap(e)).toList(),
      author: map.getString(['videoDetails', 'author']),
    );
  }

  Map toMap() {
    return {
      'title': title,
      'cover': cover,
      'videoId': videoId,
      'shortDescription': shortDescription,
      'formats': formats.map((e) => e.toMap()).toList(),
      'author': author,
    };
  }
}

class YoutubePage extends StatefulWidget {
  const YoutubePage({super.key});

  @override
  State<StatefulWidget> createState() {
    return _YoutubePage();
  }

  static String path = '/platform/youtube';

  static to() {
    return Get.toNamed(path);
  }

  static GetPage page = GetPage(
    name: path,
    page: () {
      return const YoutubePage();
    },
    transition: Transition.rightToLeft,
  );
}

class _YoutubePage extends State<YoutubePage> {
  late WebViewController _webViewController;
  final WebviewCookieManager cookieManager = WebviewCookieManager();

  Map<String, List<String>> downloads = {};
  Map<String, YoutubeVideoInfo> responseMap = {};

  StreamController<List<int>> download({
    required String url,
    required int contentLength,
    required Function(int loaded, int total) onProgress,
  }) {
    final passThrough = StreamController<List<int>>(
      onCancel: () {
        // 处理取消逻辑
      },
    );

    var dio = Dio();
    dio.httpClientAdapter = IOHttpClientAdapter(
      createHttpClient: () {
        final client = HttpClient();
        client.findProxy = (uri) {
          return 'PROXY 10.0.2.2:7890';
        };
        client.badCertificateCallback =
            (X509Certificate cert, String host, int port) => true;
        return client;
      },
    );

    const chunkSize = 10 * 1024 * 1024;
    var start = 0;
    int end = start + chunkSize;

    Future<void> getNextChunk() async {
      if (end >= contentLength) end = contentLength;

      var response = await dio.get<ResponseBody>(
        url,
        options: Options(
          headers: {
            "Range": 'bytes=$start-$end',
            "connection": 'keep-alive',
            "origin": "https://m.youtube.com",
            "referer": "https://m.youtube.com/",
          },
          responseType: ResponseType.stream,
        ),
      );

      response.data!.stream.listen(
        (chunk) {
          passThrough.add(chunk);
        },
        onDone: () {
          onProgress(end, contentLength);
          if (end != contentLength) {
            start = end + 1;
            end += chunkSize;
            getNextChunk();
          } else {
            passThrough.close();
          }
        },
        onError: (error) {
          passThrough.close();
        },
      );
    }

    getNextChunk();

    return passThrough;
  }

  @override
  void initState() {
    super.initState();

    _webViewController = WebViewController();
    _webViewController.setJavaScriptMode(JavaScriptMode.unrestricted);
    _webViewController.loadRequest(Uri.parse('https://m.youtube.com'));
    _webViewController.setUserAgent(
      'Mozilla/5.0 (iPhone; CPU iPhone OS 16_6 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.6 Mobile/15E148 Safari/604.1 Edg/131.0.0.0',
    );
    _webViewController.setNavigationDelegate(
      NavigationDelegate(
        onProgress: (int progress) {
          // Update loading bar.
        },
        onPageStarted: (String url) {},
        onPageFinished: (String url) {
          String jsCode = '''
if (!window.fetchex) {
  window.fetchex = window.fetch;

  window.resonse_whitelist = [
    'https://m.youtube.com/',
    'https://www.youtube.com/',
  ];

  window.fetch = async function (...args) {
    let requestInfo = {};
    if (args[0] && args[0].url) {
      try {
        let info = args[0].clone();
        let data = await info.text();
        try {
          data = JSON.parse(data);
        } catch (error) {}
        requestInfo = {
          key: Date.now(),
          data,
          url: info.url,
          method: info.method,
          headers: info.headers,
          href: location.href,
        };
        window.onFultterRequest.postMessage(JSON.stringify(requestInfo));
      } catch (error) {
        window.onFultterRequest.postMessage(
          JSON.stringify({
            url: args[0].url,
            error: error.toString(),
          })
        );
      }
    }
    let promise = window.fetchex(...args);
    if (args[0] && args[0].url) {
      let url = args[0].url;
      var whitelist = window.resonse_whitelist;
      if (
        whitelist.some(function (item) {
          return url.includes(item);
        })
      ) {
        try {
          let response = await promise;
          let cloneResponse = response.clone();
          let data = await cloneResponse.text();
          try {
            data = JSON.parse(data);
          } catch (error) {}
          window.onFultterResonse.postMessage(
            JSON.stringify({
              ...requestInfo,
              responseData: data,
            })
          );
        } catch (error) {
          window.onFultterResonse.postMessage(
            JSON.stringify({
              url,
              error: error.toString(),
            })
          );
        }
      }
    }
    return promise;
  };
}if (!window.fetchex) {
  window.fetchex = window.fetch;

  window.resonse_whitelist = [
    'https://m.youtube.com/',
    'https://www.youtube.com/',
  ];

  window.fetch = async function (...args) {
    let requestInfo = {};
    if (args[0] && args[0].url) {
      try {
        let info = args[0].clone();
        let data = await info.text();
        try {
          data = JSON.parse(data);
        } catch (error) {}
        requestInfo = {
          key: Date.now(),
          data,
          url: info.url,
          method: info.method,
          headers: info.headers,
          href: location.href,
        };
        window.onFultterRequest.postMessage(JSON.stringify(requestInfo));
      } catch (error) {
        window.onFultterRequest.postMessage(
          JSON.stringify({
            url: args[0].url,
            error: error.toString(),
          })
        );
      }
    }
    let promise = window.fetchex(...args);
    if (args[0] && args[0].url) {
      let url = args[0].url;
      var whitelist = window.resonse_whitelist;
      if (
        whitelist.some(function (item) {
          return url.includes(item);
        })
      ) {
        try {
          let response = await promise;
          let cloneResponse = response.clone();
          let data = await cloneResponse.text();
          try {
            data = JSON.parse(data);
          } catch (error) {}
          window.onFultterResonse.postMessage(
            JSON.stringify({
              ...requestInfo,
              responseData: data,
            })
          );
        } catch (error) {
          window.onFultterResonse.postMessage(
            JSON.stringify({
              url,
              error: error.toString(),
            })
          );
        }
      }
    }
    return promise;
  };
}
        ''';
          _webViewController.runJavaScript(jsCode);
        },
        onHttpError: (HttpResponseError error) {},
        onWebResourceError: (WebResourceError error) {},
        onNavigationRequest: (NavigationRequest request) {
          return NavigationDecision.navigate;
        },
      ),
    );

    _webViewController.addJavaScriptChannel(
      'onFultterRequest',
      onMessageReceived: (JavaScriptMessage message) {
        try {
          Map result = jsonDecode(message.message);
          String url = result['url'];
          if (url.contains('/videoplayback?expire=')) {
            var href = Uri.parse(
              (result['href'] as String).replaceAll('"', ''),
            );
            var videoId = href.queryParameters['v'];
            if (videoId == null) {
              return;
            }

            var info = responseMap[videoId];
            if (info == null) {
              return;
            }

            var ei = info.ei;

            if (!url.contains('ei=$ei')) {
              return;
            }
            downloads[videoId] = downloads[videoId] ?? ['', ''];
            if (url.contains('mime=video')) {
              downloads[videoId]![0] = url.split('&range=').first;
            }
            if (url.contains('mime=audio')) {
              downloads[videoId]![1] = url.split('&range=').first;
            }
          }
        } catch (e) {
          Tool.log(e);
        }
      },
    );

    _webViewController.addJavaScriptChannel(
      'onFultterResonse',
      onMessageReceived: (JavaScriptMessage message) {
        try {
          var result = jsonDecode(message.message);
          var url = result['url'];
          var responseData = result['responseData'];
          if (responseData is Map &&
              url is String &&
              url.contains('/youtubei/v1/player')) {
            var info = YoutubeVideoInfo.fromMap(responseData);
            responseMap[info.videoId] = info;
          }
        } catch (e) {
          Tool.log(e);
        }
      },
    );
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(child: WebViewWidget(controller: _webViewController)),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                IconButton(
                  onPressed: () {
                    _webViewController.goBack();
                  },
                  icon: FaIcon(FontAwesomeIcons.chevronLeft, size: 40.w),
                ),
                IconButton(
                  onPressed: () {
                    _webViewController.goForward();
                  },
                  icon: FaIcon(FontAwesomeIcons.chevronRight, size: 40.w),
                ),
                IconButton(
                  onPressed: () {
                    Get.back();
                  },
                  icon: Icon(Icons.reply, size: 60.w),
                ),
                IconButton(
                  onPressed: () async {
                    EasyLoading.show(
                      status: "检测下载链接".tr,
                      maskType: EasyLoadingMaskType.black,
                    );
                    try {
                      var href = await _webViewController.currentUrl();

                      var uri = Uri.parse((href as String).replaceAll('"', ''));
                      var videoId = uri.queryParameters['v'];

                      var info = responseMap[videoId];
                      var [videoUrl, audioUrl] = downloads[videoId] ?? ['', ''];

                      if (info == null ||
                          videoUrl.isEmpty ||
                          audioUrl.isEmpty) {
                        EasyLoading.dismiss();
                        EasyLoading.showToast('未检测出下载链接'.tr);
                        return;
                      }

                      EasyLoading.showToast('开始下载'.tr);

                      var videoFormat = info.formats.firstWhere(
                        (item) =>
                            item.isVideo &&
                            videoUrl.contains('itag=${item.itag}'),
                      );
                      var audioFormat = info.formats.firstWhere(
                        (item) =>
                            item.isAudio &&
                            audioUrl.contains('itag=${item.itag}'),
                      );

                      var cachepath = await Tool.getAppCachePath();
                      var dirpath = '$cachepath/$videoId';

                      var doc = Directory(dirpath);
                      if (doc.existsSync()) {
                        await doc.delete(recursive: true);
                      }
                      await doc.create(recursive: true);

                      var videoFile = File('$dirpath/video.${videoFormat.ext}');
                      if (videoFile.existsSync()) {
                        await videoFile.delete(recursive: true);
                      }

                      var videoStream = download(
                        url: videoUrl,
                        contentLength: videoFormat.contentLength,
                        onProgress: (loaded, total) {
                          var progress = loaded / total;
                          EasyLoading.showProgress(
                            status: '${'视频下载：'.tr}$loaded/$total',
                            progress,
                            maskType: EasyLoadingMaskType.black,
                          );
                        },
                      );

                      var videocom = Completer();

                      videoStream.stream.listen(
                        (data) {
                          videoFile.writeAsBytesSync(
                            data,
                            mode: FileMode.append,
                          );
                        },
                        onDone: () {
                          videocom.complete();
                        },
                        onError: (error) {
                          videocom.completeError(error);
                        },
                      );

                      await videocom.future;

                      var audioFile = File('$dirpath/audio.${audioFormat.ext}');

                      if (audioFile.existsSync()) {
                        await audioFile.delete(recursive: true);
                      }

                      var audioStream = download(
                        url: audioUrl,
                        contentLength: audioFormat.contentLength,
                        onProgress: (loaded, total) {
                          var progress = loaded / total;
                          EasyLoading.showProgress(
                            status: '${'音频下载：'.tr}$loaded/$total',
                            progress,
                            maskType: EasyLoadingMaskType.black,
                          );
                        },
                      );

                      var audiocom = Completer();

                      audioStream.stream.listen(
                        (data) {
                          audioFile.writeAsBytesSync(
                            data,
                            mode: FileMode.append,
                          );
                        },
                        onDone: () {
                          audiocom.complete();
                        },
                        onError: (error) {
                          audiocom.completeError(error);
                        },
                      );

                      await audiocom.future;

                      EasyLoading.showToast('下载完成'.tr);

                      var assetspath = await Tool.getAppAssetsPath();

                      await Directory(
                        '$assetspath/youtube',
                      ).create(recursive: true);
                      var mergeFile = File(
                        '$assetspath/youtube/${info.title.replaceAll('/', '_')}.mp4',
                      );

                      if (mergeFile.existsSync()) {
                        await mergeFile.delete(recursive: true);
                      }

                      await FfmpegTool.merge(
                        videoInput: videoFile.path,
                        audioInput: audioFile.path,
                        output: mergeFile.path,
                        onProgress: (progress, duration) {
                          EasyLoading.showProgress(
                            status:
                                '${'转码：'.tr}${(duration * progress / 100).round()}/$duration',
                            progress / 100,
                            maskType: EasyLoadingMaskType.black,
                          );
                        },
                      );

                      await doc.delete(recursive: true);

                      var coverFile = await Tool.cacheImg(
                        url:
                            'https://cdn.swisscows.com/image?url=${Uri.decodeComponent(info.cover)}',
                      );

                      EasyLoading.showToast('转码完成'.tr);

                      var media = MediaDbModel(
                        name: info.title,
                        platform: MediaPlatformType.local,
                        type: MediaTagType.video,
                        local: mergeFile.path,
                        relationId: info.videoId,
                        albumName: 'youtube',
                        artist: info.author,
                        mimeType: 'video/mp4',
                        cover: coverFile.path,
                      );

                      var id = await MediaDbModel.insert(media);
                      media.id = id;
                      var [album] = await AlbumDbModel.findByRelationIds(
                        ids: [MediaPlatformType.local.name],
                        type: media.type,
                      );
                      album.songIds.add(media.id);
                      await album.update();

                      EasyLoading.showToast('数据已添加到视频库'.tr);
                    } catch (e) {
                      Tool.log(e);
                      EasyLoading.dismiss();
                      EasyLoading.showToast('下载异常'.tr);
                    }
                  },
                  icon: FaIcon(FontAwesomeIcons.download, size: 40.w),
                ),
                IconButton(
                  onPressed: () {
                    Tool.showBottomSheet(
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 20.w,
                          vertical: 30.w,
                        ),
                        width: double.infinity,
                        child: Column(
                          children: [
                            Text("下载须知".tr, style: TextStyle(fontSize: 32.sp)),
                            SizedBox(height: 20.w),
                            SizedBox(
                              width: double.infinity,
                              height: 200.w,
                              child: Opacity(
                                opacity: 0.7,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '1、请跳过广告在进行下载，防止解析到广告内容'.tr,
                                      style: TextStyle(fontSize: 30.sp),
                                    ),
                                    SizedBox(height: 10.w),
                                    Text(
                                      '2、请切换到你需要的分辨率后，再进行下载'.tr,
                                      style: TextStyle(fontSize: 30.sp),
                                    ),
                                    SizedBox(height: 10.w),
                                    Text(
                                      '3、下载完成后将会保存到本地视频中'.tr,
                                      style: TextStyle(fontSize: 30.sp),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  icon: FaIcon(FontAwesomeIcons.circleInfo, size: 40.w),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
