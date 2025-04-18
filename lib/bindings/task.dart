import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:pms/apis/export.dart';
import 'package:pms/db/export.dart';
import 'package:pms/pages/export.dart';
import 'package:pms/utils/export.dart';

class TaskController extends GetxController {
  final RxList<TaskDbModel> downloads = RxList<TaskDbModel>([]);
  final RxList<TaskDbModel> uploads = RxList<TaskDbModel>([]);
  final RxList<TaskDbModel> formats = RxList<TaskDbModel>([]);
  final Map<int, MediaDbModel> mediaMaps = {};

  final Map<int, List<DioChainResponse<ResponseBody>>> _downloadQue = {};
  final Map<int, DioChainResponse?> _uploadQue = {};
  final Map<int, Future?> _formatQue = {};

  int maxLimit = 2;
  Timer? _reportTaskTimeRef;
  final Map<String, List<String>> _aliReportRecord = {};

  _initRun() async {
    var list = await TaskDbModel.tasks();

    var medias = await MediaDbModel.findByIds(
      list.map((item) => item.mediaId).toList(),
    );

    for (var item in medias) {
      mediaMaps[item.id] = item;
    }

    for (var item in list) {
      switch (item.type) {
        case MediaTaskType.download:
          downloads.add(item);
          break;
        case MediaTaskType.upload:
          uploads.add(item);
          break;
        case MediaTaskType.format:
          formats.add(item);
          break;
      }
    }
    _runDownloadTask();
    _runUploadTask();
    _runFormatTask();
  }

  createTask({
    required MediaDbModel media,
    required MediaTaskType taskType,
    int uploadAlbumId = -1,
    String remark = '',
  }) async {
    var isDownload = taskType == MediaTaskType.download;
    var isUpload = taskType == MediaTaskType.upload;
    var isFormat = taskType == MediaTaskType.format;

    var tasks = isDownload ? downloads : (isUpload ? uploads : formats);
    var isExist = tasks.firstWhereOrNull((item) {
          var info = mediaMaps[item.mediaId];
          if (info == null) {
            return false;
          }
          return media.relationId == info.relationId &&
              media.platform == info.platform &&
              media.type == info.type &&
              item.uploadAlbumId == uploadAlbumId;
        }) !=
        null;

    Tool.log([isExist, taskType, media.local]);

    if (isExist) {
      return;
    }

    if (media.id == -1) {
      var id = await MediaDbModel.insert(media);
      media.id = id;
    }
    var task = TaskDbModel(
      platform: media.platform,
      mediaId: media.id,
      type: taskType,
      status: MediaTaskStatus.wait,
      loaded: 0,
      total: 0,
      uploadAlbumId: uploadAlbumId,
      remark: remark,
    );
    var id = await TaskDbModel.insert(task);
    task.id = id;
    mediaMaps[media.id] = media;
    if (isDownload) {
      downloads.add(task);
      _runDownloadTask();
    }
    if (isUpload) {
      uploads.add(task);
      _runUploadTask();
    }
    if (isFormat) {
      formats.add(task);
      _runFormatTask();
    }
  }

  _startAliReportTask(String userId, String fileId) {
    _aliReportRecord[userId] = _aliReportRecord[userId] ?? [];
    _aliReportRecord[userId]!.add(fileId);
    if (_reportTaskTimeRef != null) {
      return;
    }
    _reportTaskTimeRef = Timer.periodic(const Duration(seconds: 4), (_) async {
      var uses = await UserDbModel.findByPlatform(MediaPlatformType.aliyun);
      for (var item in _aliReportRecord.entries) {
        var key = item.key;
        // var value = item.value;
        var user = uses.firstWhere((item) => item.relationId == key);
        await user.updateToken();
        AliyunApi.reportTask(
          sliceNum: 2,
          driveId: user.extra.driveId,
          xDeviceId: user.extra.xDeviceId,
          token: user.accessToken,
          xSignature: user.extra.xSignature,
        );
      }
    });
  }

  _stopAliReportTask(String userId, String fileId) async {
    var list = _aliReportRecord[userId];

    if (list != null && list.isNotEmpty) {
      list.remove(fileId);
    }

    if (list != null && list.isEmpty) {
      _aliReportRecord.remove(userId);
      var uses = await UserDbModel.findByPlatform(MediaPlatformType.aliyun);
      var user = uses.firstWhere((item) => item.relationId == userId);
      AliyunApi.reportTask(
        sliceNum: 0,
        driveId: user.extra.driveId,
        xDeviceId: user.extra.xDeviceId,
        token: user.accessToken,
        xSignature: user.extra.xSignature,
      );
    }

    var isStop = true;
    for (var item in _aliReportRecord.values) {
      if (item.isNotEmpty) {
        isStop = false;
        break;
      }
    }
    if (isStop) {
      _reportTaskTimeRef?.cancel();
      _reportTaskTimeRef = null;
    }
  }

  _runDownloadTask() async {
    if (_downloadQue.length >= maxLimit) {
      return;
    }

    for (var index = 0; index < downloads.length; index++) {
      if (_downloadQue.length >= maxLimit) {
        break;
      }
      var task = downloads[index];
      if (task.status != MediaTaskStatus.wait) {
        continue;
      }

      var media = mediaMaps[task.mediaId];
      if (media == null) {
        task.status = MediaTaskStatus.error;
        continue;
      }

      try {
        _downloadQue[task.id] = [];
        task.status = MediaTaskStatus.pending;

        var cachepath = await Tool.getAppCachePath();
        var dirPath = '$cachepath/${media.platform.name}';
        await Directory(dirPath).create(recursive: true);

        var [audioUrl, videoUrl] = await media.getDownloadUrl();

        var referer = media.extra.referer;

        download(
          String url,
          void Function(int loaded, int total) onProgress,
        ) async {
          try {
            if (url.isEmpty) {
              return '';
            }

            bool isVideoUrl = url == videoUrl;
            bool isAudioUrl = url == audioUrl;

            /// 如果下载的资源 是视频的音频源 并且audioTrack存在 则该音频已下载完成
            if (media.type == MediaTagType.video &&
                isAudioUrl &&
                media.audioTrack.isNotEmpty) {
              return media.audioTrack;
            }

            /// 如果下载的资源 是视频的视频源 并且local存在 则该视频已下载完成
            if (media.type == MediaTagType.video &&
                isVideoUrl &&
                media.local.isNotEmpty) {
              return media.local;
            }

            /// 如果下载的资源是音频  并且local存在 则该音频已下载完成
            if (media.type == MediaTagType.muisc &&
                isAudioUrl &&
                media.local.isNotEmpty) {
              return media.local;
            }

            var urlname = await Tool.parseUrlAssetName(
              url: url,
              headers: {'referer': referer},
            );

            var ext = urlname.split('.').last;

            var basepath =
                '$dirPath/${media.name.replaceAll(RegExp(r'[/.]'), '_')}';

            var savePath = '$basepath.$ext';

            if (media.type == MediaTagType.video && isAudioUrl) {
              savePath = '${savePath}_audio_track.$ext';
            }

            var tempfile = File(savePath);

            var cachePosition =
                tempfile.existsSync() ? tempfile.lengthSync() : 0;

            DioChainResponse<ResponseBody>? chain;

            if (task.isAliyunPlatform) {
              chain = AliyunApi.download(url: url, referer: referer);
            }

            if (task.isNeteasePlatform) {
              chain = NeteaseApi.download(url: url);
            }

            if (task.isBiliPlatform) {
              chain = BiliApi.download(url: url, referer: referer);
            }

            if (chain == null) {
              return '';
            }

            _downloadQue[task.id]!.add(chain.setRange(cachePosition));

            var response = await chain.onReceiveProgress((count, total) {
              onProgress(cachePosition + count, cachePosition + total);
            }).getData();

            await Tool.saveAsset(
              response: response,
              path: savePath,
              start: cachePosition,
            );

            if (media.type == MediaTagType.video) {
              if (isVideoUrl) {
                media.local = savePath;
              }
              if (isAudioUrl) {
                media.audioTrack = savePath;
              }
            }
            if (media.type == MediaTagType.muisc && isAudioUrl) {
              media.local = savePath;
            }
            await media.update();
            await task.update();

            return savePath;
          } catch (e) {
            return Future.error(e);
          }
        }

        runTask() async {
          try {
            if (task.isAliyunPlatform) {
              _startAliReportTask(media.relationUserId, media.relationId);
            }

            List<int> loadeds = [0, 0];
            List<int> totals = [0, 0];

            updateProgress() {
              task.loaded = loadeds.fold(0, (a, b) => a + b);
              task.total = totals.fold(0, (a, b) => a + b);
            }

            var sources = media.type == MediaTagType.video
                ? [audioUrl, videoUrl]
                : [audioUrl];

            List<Future> promises = sources.asMap().entries.map((item) {
              var index = item.key;
              var url = item.value;
              return download(url, (loaded, total) {
                loadeds[index] = loaded;
                totals[index] = total;
                updateProgress();
              });
            }).toList();

            await Future.wait(promises);

            task.remove();
            downloads.remove(task);

            /// 如果下载的音频不是 常用格式 则进行转码 允许视频当音频
            if (media.type == MediaTagType.muisc &&
                !Tool.isAudioFile(media.local)) {
              createTask(media: media, taskType: MediaTaskType.format);
            }

            if (media.type == MediaTagType.video &&
                    !Tool.isVideoFile(media.local) ||
                media.audioTrack.isNotEmpty) {
              createTask(media: media, taskType: MediaTaskType.format);
            }

            if (Tool.isAudioFile(media.local) ||
                Tool.isVideoFile(media.local)) {
              var assetpath = await Tool.getAppAssetsPath();
              var cachepath = await Tool.getAppCachePath();
              var cachefile = File(media.local);

              var savepath = media.local.replaceAll(cachepath, assetpath);

              await Directory(
                savepath.substring(0, savepath.lastIndexOf('/')),
              ).create(recursive: true);

              var file = await cachefile.copy(savepath);

              media.local = file.path;

              await media.update();

              var [album] = await AlbumDbModel.findByRelationIds(
                ids: [MediaPlatformType.local.name],
                type: media.type,
              );
              album.songIds.add(media.id);
              await album.update();
            }

            var controller = Get.find<HomeController>();

            if (media.isAudio) {
              await controller.initMuiceAlbums();
            }

            if (media.isVideo) {
              await controller.initVideoAlbums();
            }
          } catch (e) {
            pauseTask(task);
          } finally {
            _downloadQue.remove(task.id);
            _runDownloadTask();
            if (task.isAliyunPlatform) {
              _stopAliReportTask(media.relationUserId, media.relationId);
            }
          }
        }

        runTask();
      } catch (e) {
        pauseTask(task);
      }
    }
  }

  _runUploadTask() async {
    if (_uploadQue.length >= maxLimit) {
      return;
    }

    for (var index = 0; index < uploads.length; index++) {
      if (_uploadQue.length >= maxLimit) {
        break;
      }
      var task = uploads[index];
      if (task.status != MediaTaskStatus.wait) {
        continue;
      }
      var media = mediaMaps[task.mediaId];
      if (media == null) {
        task.status = MediaTaskStatus.error;
        continue;
      }

      task.status = MediaTaskStatus.pending;

      _uploadQue[task.id] = null;

      upload() async {
        try {
          var [album] = await AlbumDbModel.findByIds([task.uploadAlbumId]);
          var [user] = await UserDbModel.findByRelationIds([
            album.relationUserId,
          ], album.platform);
          await user.updateToken();

          if (album.isAliyunPlatform) {
            var uploader = await AliyunApi.getUploadPaths(
              filePath: media.local,
              driveId: user.extra.driveId,
              xDeviceId: user.extra.xDeviceId,
              token: user.accessToken,
              xSignature: user.extra.xSignature,
              parentFileId: album.relationId,
            );

            task.total = uploader.fileSize;
            for (var i = (task.loaded / uploader.fileSize).floor();
                i < uploader.partUrls.length;
                i++) {
              var partUrl = uploader.partUrls[i];
              var chunk = uploader.getPartChunk(i);
              var promise = AliyunApi.uploadPart(
                partUrl: partUrl,
                chunk: chunk,
              );
              _uploadQue[task.id] = promise;
              await promise.onSendProgress((loaded, _) {
                task.loaded = i * uploader.chunkSize + loaded;
              });
              task.loaded = min(((i + 1) * uploader.chunkSize), task.total);
              await task.update();
            }

            if (uploader.partUrls.isNotEmpty) {
              await AliyunApi.mergeUploadPart(
                fileId: uploader.fileId,
                uploadId: uploader.uploadId,
                driveId: user.extra.driveId,
                xDeviceId: user.extra.xDeviceId,
                token: user.accessToken,
                xSignature: user.extra.xSignature,
              );
            }

            await task.remove();
            uploads.remove(task);
          }

          if (album.isNeteasePlatform) {
            var domains = await NeteaseApi.getUploadDomains().getData();

            var file = await NeteaseApi.uploadCheck(
              cookie: user.accessToken,
              filepath: media.local,
            ).getData();

            file = await NeteaseApi.uploadCreate(
              cookie: user.accessToken,
              file: file,
            ).getData();
            task.total = file.fileSize;
            if (file.needUpload) {
              var promise = NeteaseApi.upload(
                cookie: user.accessToken,
                file: file,
                domain: domains.first,
              );
              _uploadQue[task.id] = promise;
              await promise.onSendProgress((loaded, total) {
                task.loaded = loaded;
              });
            }
            var songId = await NeteaseApi.uploadFileSave(
              cookie: user.accessToken,
              file: file,
            ).getData();

            if (songId == 0) {
              throw '保存上传文件异常'.tr;
            }

            await NeteaseApi.uploadPublic(
              cookie: user.accessToken,
              songId: songId,
            );

            await task.remove();
            uploads.remove(task);
          }
        } catch (e) {
          task.status = MediaTaskStatus.pause;
          await task.update();
        } finally {
          _uploadQue.remove(task.id);
          _runUploadTask();
        }
      }

      upload();
    }
  }

  _runFormatTask() async {
    if (_formatQue.length >= maxLimit) {
      return;
    }
    for (var index = 0; index < formats.length; index++) {
      if (_formatQue.length >= maxLimit) {
        break;
      }
      var task = formats[index];
      if (task.status != MediaTaskStatus.wait) {
        continue;
      }

      var media = mediaMaps[task.mediaId];

      if (media == null) {
        task.status = MediaTaskStatus.error;
        continue;
      }

      _formatQue[task.id] = null;
      task.status = MediaTaskStatus.pending;

      var controller = Get.find<HomeController>();

      if (media.isAudio) {
        var index = media.local.lastIndexOf('.');
        var cachepath = await Tool.getAppCachePath();
        var assetpath = await Tool.getAppAssetsPath();
        var audioOutput =
            '${media.local.replaceAll(cachepath, assetpath).substring(0, index)}.flac';
        var outputFile = File(audioOutput);
        if (outputFile.existsSync()) {
          await outputFile.delete(recursive: true);
        }
        await Directory(
          audioOutput.substring(0, audioOutput.lastIndexOf('/')),
        ).create(recursive: true);

        var mediaInfo = await FfmpegTool.getMediaInformation(media.local);

        String? album = media.albumName;
        String? artist = media.artist;
        String? title = media.name;
        String? cover = File(media.cover).existsSync() ? media.cover : null;

        if (mediaInfo != null) {
          var tag = mediaInfo.getTags();
          if (tag != null) {
            album = tag['album'] != null ? null : album;
            artist = tag['artist'] != null ? null : artist;
            title = tag['title'] != null ? null : title;
          }
        }

        var promise = FfmpegTool.convertAudio(
          input: media.local,
          output: audioOutput,
          album: album,
          artist: artist,
          title: title,
          coverPath: cover,
          onProgress: (progress, duration) {
            task.total = duration.round();
            task.loaded = (progress / 100 * duration).round();
          },
        );
        _formatQue[task.id] = promise;
        promise.then((_) async {
          var oldPath = media.local;
          media.local = audioOutput;
          var file = File(oldPath);
          await media.update();
          if (file.existsSync()) {
            await file.delete(recursive: true);
          }
          await task.remove();
          formats.remove(task);

          var [album] = await AlbumDbModel.findByRelationIds(
            ids: [MediaPlatformType.local.name],
            type: media.type,
          );
          album.songIds.add(media.id);
          await album.update();
        }).catchError((e) {
          task.status = MediaTaskStatus.pause;
          task.update();
        }).whenComplete(() {
          controller.initMuiceAlbums();
          _formatQue.remove(task.id);
          _runFormatTask();
        });
      }

      if (media.isVideo) {
        var index = media.local.lastIndexOf('.');
        var cachepath = await Tool.getAppCachePath();
        var assetpath = await Tool.getAppAssetsPath();
        var videoOutput =
            '${media.local.replaceAll(cachepath, assetpath).substring(0, index)}.mp4';
        var outputFile = File(videoOutput);
        if (outputFile.existsSync()) {
          await outputFile.delete(recursive: true);
        }
        await Directory(
          videoOutput.substring(0, videoOutput.lastIndexOf('/')),
        ).create(recursive: true);
        var promise = FfmpegTool.merge(
          videoInput: media.local,
          audioInput: media.audioTrack,
          output: videoOutput,
          onProgress: (progress, duration) {
            task.total = duration.round();
            task.loaded = (progress / 100 * duration).round();
          },
        );
        _formatQue[task.id] = promise;
        promise.then((_) async {
          var oldPath = media.local;
          var oldAudioTrack = media.audioTrack;
          media.local = videoOutput;
          media.audioTrack = '';
          await media.update();
          var file = File(oldPath);
          if (file.existsSync()) {
            await file.delete(recursive: true);
          }
          var audioFile = File(oldAudioTrack);
          if (audioFile.existsSync()) {
            await audioFile.delete(recursive: true);
          }
          await task.remove();
          formats.remove(task);
          var [album] = await AlbumDbModel.findByRelationIds(
            ids: [MediaPlatformType.local.name],
            type: media.type,
          );
          album.songIds.add(media.id);
          await album.update();
        }).catchError((e) {
          task.status = MediaTaskStatus.pause;
          task.update();
        }).whenComplete(() {
          _formatQue.remove(task.id);
          controller.initVideoAlbums();
          _runFormatTask();
        });
      }
    }
  }

  pauseTask(TaskDbModel task) async {
    task.status = MediaTaskStatus.pause;
    var taskId = task.id;
    _downloadQue[taskId]?.forEach((item) {
      if (item.isCanceled) {
        return;
      }
      item.cancel('暂停任务'.tr);
    });
    _uploadQue[taskId]?.cancel('暂停任务'.tr);
    await task.update();
  }

  startTask(TaskDbModel task) {
    task.status = MediaTaskStatus.wait;
    _runDownloadTask();
    _runFormatTask();
    _runUploadTask();
  }

  removeTask(TaskDbModel task) async {
    pauseTask(task);
    await task.remove();
    switch (task.type) {
      case MediaTaskType.download:
        downloads.remove(task);
        break;
      case MediaTaskType.upload:
        uploads.remove(task);
        break;
      case MediaTaskType.format:
        formats.remove(task);
        break;
    }
    // var cachepath = await Tool.getAppCachePath();
    // var media = mediaMaps[task.mediaId];
    // var dirPath = '$cachepath/${media.platform.name}/';
    // final directory = Directory(dirPath);
    // if (directory.existsSync()) {
    //   directory.deleteSync(recursive: true);
    // }
  }

  @override
  void onInit() {
    super.onInit();
    _initRun();
  }

  @override
  void dispose() {
    super.dispose();
    _reportTaskTimeRef?.cancel();
  }
}
