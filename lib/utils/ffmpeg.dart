import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter/ffmpeg_kit_config.dart';
import 'package:ffmpeg_kit_flutter/ffprobe_kit.dart';
import 'package:ffmpeg_kit_flutter/media_information.dart';
import 'package:ffmpeg_kit_flutter/media_information_session.dart';
import 'package:ffmpeg_kit_flutter/statistics.dart';
import 'package:pms/utils/export.dart';

class FfmpegTool {
  static final List<void Function(Statistics stat)> _callbaks = [];
  static bool _enable = false;

  static void Function() onStatistics(void Function(Statistics stat) callback) {
    if (_enable == false) {
      FFmpegKitConfig.enableStatisticsCallback((stat) {
        for (var fn in _callbaks) {
          fn(stat);
        }
      });
      _enable = true;
    }
    _callbaks.add(callback);
    return () {
      offStatistics(callback);
    };
  }

  static offStatistics(void Function(Statistics stat) callback) {
    _callbaks.remove(callback);
  }

  static Future<MediaInformation?> getMediaInformation(String input) async {
    var session = await FFprobeKit.getMediaInformation(input);
    return session.getMediaInformation();
  }

  static Future<dynamic> convertAudio({
    required String input,
    required String output,
    required void Function(int progress, double duration) onProgress,
    String? artist,
    String? album,
    String? title,
    String? coverPath,
    double? startTime,
    double? endTime,
  }) async {
    var info = await FFprobeKit.getMediaInformation(input);
    double totalDuration =
        double.parse(info.getMediaInformation()?.getDuration() ?? '0');
    var off = onStatistics((stat) {
      double currentTime = stat.getTime() / 1000;
      int progress = ((currentTime / totalDuration) * 100).round();
      onProgress(progress, totalDuration);
    });

    try {
      // 构建 FFmpeg 命令
      String command = '-i "$input"';
      if (coverPath != null) {
        command += ' -i "$coverPath"';
      }
      if (startTime != null) {
        command += ' -ss $startTime';
      }
      if (endTime != null) {
        command += ' -to $endTime';
      }
      command += ' -map 0:a';
      if (coverPath != null) command += ' -map 1:v -disposition:v attached_pic';
      if (artist != null) command += ' -metadata artist="$artist"';
      if (album != null) command += ' -metadata album="$album"';
      if (title != null) command += ' -metadata title="$title"';
      command += ' -c:a flac "$output"';

      var session = await FFmpegKit.execute(command);
      var returnCode = await session.getReturnCode();
      off();
      if (returnCode!.isValueSuccess()) {
        return returnCode.getValue();
      }
      var logs = await session.getAllLogs();
      String message = '';
      for (var log in logs) {
        message += log.getMessage();
      }
      return Future.error(message);
    } catch (e) {
      off();
      return Future.error(e);
    }
  }

  static Future cropVideo({
    required String input,
    required String output,
    required void Function(int progress, double duration) onProgress,
    double? startTime,
    double? endTime,
  }) async {
    var info = await FFprobeKit.getMediaInformation(input);
    double totalDuration =
        double.parse(info.getMediaInformation()?.getDuration() ?? '');
    var off = onStatistics((stat) {
      double currentTime = stat.getTime() / 1000;
      int progress = ((currentTime / totalDuration) * 100).round();
      onProgress(progress, totalDuration);
    });
    try {
      String command = '-i "$input"';
      if (startTime != null) {
        command += ' -ss $startTime';
      }
      if (endTime != null) {
        command += ' -to $endTime';
      }
      command += ' -c copy "$output"';
      var session = await FFmpegKit.execute(command);
      var returnCode = await session.getReturnCode();
      off();
      if (returnCode!.isValueSuccess()) {
        return returnCode.getValue();
      }
      var logs = await session.getAllLogs();
      String message = '';
      for (var log in logs) {
        message += log.getMessage();
      }
      return Future.error(message);
    } catch (e) {
      off();
      return Future.error(e);
    }
  }

  static Future merge({
    required String videoInput,
    String? audioInput, // 改为可选
    required String output,
    required void Function(int progress, double duration) onProgress,
  }) async {
    var info = await FFprobeKit.getMediaInformation(videoInput);
    double totalDuration =
        double.parse(info.getMediaInformation()?.getDuration() ?? '0.0');

    var off = onStatistics((stat) {
      double currentTime = stat.getTime() / 1000;
      int progress = totalDuration == 0
          ? 0
          : ((currentTime / totalDuration) * 100).round();
      onProgress(progress, totalDuration);
    });

    try {
      // 构建命令
      String command;
      if (audioInput != null && audioInput.isNotEmpty) {
        // 有音频：合成视频+音频
        command =
            '-i "$videoInput" -i "$audioInput" -c:v copy -c:a aac -strict experimental "$output"';
      } else {
        // 没音频：仅处理视频（保留原视频轨道）
        command = '-i "$videoInput" -c:v copy "$output"';
      }

      var session = await FFmpegKit.execute(command);
      var returnCode = await session.getReturnCode();
      off();

      if (returnCode!.isValueSuccess()) {
        return returnCode.getValue();
      }

      var logs = await session.getAllLogs();
      String message = logs.map((e) => e.getMessage()).join();
      return Future.error(message);
    } catch (e) {
      off();
      return Future.error(e);
    }
  }
}
