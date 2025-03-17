library db_model;

export './album.dart';
export './media.dart';
export './user.dart';
export './task.dart';

enum MediaPlatformType { bili, aliyun, netease, local, action }

enum MediaTagType { muisc, video, action }

enum MediaTaskStatus {
  wait,
  pending,
  pause,
  done,
  error,
}

enum MediaTaskType { download, upload, format }
