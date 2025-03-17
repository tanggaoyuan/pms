import 'dart:convert';
import 'package:pms/apis/export.dart';
import 'package:pms/components/export.dart';
import 'package:pms/db/export.dart';
import 'package:pms/utils/export.dart';
import 'package:sqflite/sqflite.dart';

class MediaDbModel {
  static String tableName = 'media';

  late int id;
  late String cover;
  late String name;
  late String local;
  late NetLrc lyric;

  /// 视频 音频文件路径
  late String audioTrack;
  late String albumName;
  late String artist;

  late MediaPlatformType platform;
  late MediaTagType type;

  late String relationId;
  late String relationAlbumId;
  late String relationUserId;
  late String mimeType;

  late int userId;

  late MediaDbExtraModel extra;
  late int updateTime;
  late int createTime;

  MediaDbModel({
    required this.name,
    required this.platform,
    required this.type,
    this.audioTrack = '',
    this.relationUserId = '',
    this.relationAlbumId = '',
    this.relationId = '',
    this.id = -1,
    this.cover = '',
    this.userId = -1,
    this.local = '',
    this.albumName = '',
    this.artist = '',
    NetLrc? lyric,
    this.mimeType = '',
    String? extra,
    int? updateTime,
    int? createTime,
  }) {
    this.extra = MediaDbExtraModel.format(extra);
    DateTime now = DateTime.now();
    cover = cover.isEmpty ? ImgCompIcons.mainCover : cover;
    this.lyric = lyric ?? NetLrc(mainLrc: '', translateLrc: '', romaLrc: '');
    int timestampInMilliseconds = now.millisecondsSinceEpoch;
    this.createTime = createTime ?? timestampInMilliseconds;
    this.updateTime = updateTime ?? timestampInMilliseconds;
  }

  bool get isAudio {
    return type == MediaTagType.muisc;
  }

  bool get isVideo {
    return type == MediaTagType.video;
  }

  bool get isAliyunPlatform {
    return platform == MediaPlatformType.aliyun;
  }

  bool get isNeteasePlatform {
    return platform == MediaPlatformType.netease;
  }

  bool get isBiliPlatform {
    return platform == MediaPlatformType.bili;
  }

  String get cacheKey {
    return '${platform.name}@$relationId';
  }

  @override
  String toString() {
    return jsonEncode(toMap());
  }

  /// [audio,video]
  Future<List<String>> getDownloadUrl() async {
    var [user] = await UserDbModel.findByRelationIds([
      relationUserId,
    ], platform);

    await user.updateToken();
    if (isAliyunPlatform) {
      var url =
          await AliyunApi.getDonwloadUrl(
            fileId: relationId,
            driveId: user.extra.driveId,
            xDeviceId: user.extra.xDeviceId,
            token: user.accessToken,
            xSignature: user.extra.xSignature,
          ).getData();
      if (isAudio) {
        return [url, ''];
      } else {
        return ['', url];
      }
    }

    if (isNeteasePlatform) {
      var url =
          await NeteaseApi.getPlayLink(
            cookie: user.accessToken,
            id: relationId,
          ).getData();
      return [url, ''];
    }

    if (isBiliPlatform) {
      var [info] =
          await BiliApi.getVideoSampleInfo(
            bvid: relationId,
            cookie: user.accessToken,
          ).getData();
      var media =
          await BiliApi.getPlayInfo(
            bvid: relationId,
            cid: info.cid,
            cookie: user.accessToken,
            imgKey: user.extra.imgKey,
            subKey: user.extra.subKey,
          ).getData();
      return [media.audios.first.url, media.videos.first.url];
    }

    return ['', ''];
  }

  /// [audio,video]
  Future<List<String>> getPlayUrl() async {
    if (local.isNotEmpty) {
      return isAudio ? [local, ''] : [audioTrack, local];
    }

    var [user] = await UserDbModel.findByRelationIds([
      relationUserId,
    ], platform);

    if (isAliyunPlatform) {
      await user.updateToken();
      if (!mimeType.contains('video')) {
        var list =
            await AliyunApi.getAudioPreviewList(
              fileId: relationId,
              driveId: user.extra.driveId,
              xDeviceId: user.extra.xDeviceId,
              token: user.accessToken,
              xSignature: user.extra.xSignature,
            ).getData();
        return [list.last.url, ''];
      } else {
        var list =
            await AliyunApi.getVideoPreviewList(
              fileId: relationId,
              driveId: user.extra.driveId,
              xDeviceId: user.extra.xDeviceId,
              token: user.accessToken,
              xSignature: user.extra.xSignature,
            ).getData();
        return ['', list.last.url];
      }
    }

    // dash 播放
    if (isBiliPlatform) {
      await user.updateToken();
      var [info] =
          await BiliApi.getVideoSampleInfo(
            bvid: relationId,
            cookie: user.accessToken,
          ).getData();

      var dash =
          await BiliApi.getPlayDash(
            bvid: relationId,
            cid: info.cid,
            cookie: user.accessToken,
            imgKey: user.extra.imgKey,
            subKey: user.extra.subKey,
          ).getData();

      var filepath = await Tool.getAppCachePath();

      await dash.saveXml("$filepath/bili.mpd");

      return ["", "$filepath/bili.mpd"];
    }

    var [audio, video] = await getDownloadUrl();

    return [audio, video];
  }

  static MediaDbModel fromAliFile({
    required AlbumDbModel album,
    required UserDbModel user,
    required AliFile file,
    required MediaTagType type,
  }) {
    return MediaDbModel(
      name: file.name,
      platform: MediaPlatformType.aliyun,
      cover: file.thumbnail,
      relationId: file.fileId,
      relationUserId: user.relationId,
      userId: user.id,
      type: type,
      albumName: file.albumName,
      artist: file.artist,
      relationAlbumId: album.relationId,
      mimeType: file.mimeType,
      extra: jsonEncode({'referer': user.extra.referer}),
    );
  }

  static MediaDbModel fromNetSong({
    required AlbumDbModel album,
    required UserDbModel user,
    required NetSong file,
    required MediaTagType type,
  }) {
    return MediaDbModel(
      name: file.name,
      platform: MediaPlatformType.netease,
      cover: file.cover,
      relationId: file.id.toString(),
      userId: user.id,
      albumName: file.albumName,
      artist: file.alia.join('/'),
      relationAlbumId: album.relationId,
      relationUserId: user.relationId,
      mimeType: 'audio/mpeg',
      type: type,
    );
  }

  static MediaDbModel fromBili({
    required AlbumDbModel album,
    required UserDbModel user,
    required BliVideoInfo file,
    required MediaTagType type,
  }) {
    return MediaDbModel(
      name: file.title,
      platform: MediaPlatformType.bili,
      cover: file.cover.replaceAll('http://', 'https://'),
      relationId: file.bvid,
      userId: user.id,
      relationUserId: user.relationId,
      relationAlbumId: album.relationId,
      albumName: album.name,
      artist: file.upperName,
      type: type,
      mimeType: 'video/m4s',
      extra: jsonEncode({
        'referer': user.extra.referer,
        'resourceId': '${file.id}:${file.type}',
      }),
    );
  }

  static MediaDbModel fromMap(Map map) {
    return MediaDbModel(
      id: map['id'],
      name: map['name'],
      platform: MediaPlatformType.values.firstWhere(
        (e) => e.toString().contains(map['platform']),
      ),
      cover: map['cover'],
      relationId: map['relationId'],
      relationUserId: map['relationUserId'],
      userId: map['userId'],
      type: MediaTagType.values.firstWhere(
        (e) => e.toString().contains(map['type']),
      ),
      albumName: map['albumName'],
      extra: map['extra'],
      local: map['local'],
      artist: map['artist'],
      relationAlbumId: map['relationAlbumId'] ?? '',
      mimeType: map['mimeType'] ?? '',
      lyric: NetLrc.fromJson(map['lyric']),
      audioTrack: map['audioTrack'],
      updateTime: map['updateTime'],
      createTime: map['createTime'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'platform': platform.name,
      'cover': cover,
      'relationId': relationId,
      'relationUserId': relationUserId,
      'relationAlbumId': relationAlbumId,
      'userId': userId,
      'type': type.name,
      'local': local,
      'lyric': lyric.toString(),
      "albumName": albumName,
      'extra': extra.toString(),
      'artist': artist,
      'updateTime': updateTime,
      'createTime': createTime,
      'audioTrack': audioTrack,
      'mimeType': mimeType,
    };
  }

  Future<int> remove() async {
    var db = await DbHelper.open();
    return db.delete(tableName, where: 'id = ?', whereArgs: [id]);
  }

  Future<MediaDbModel> update() async {
    var db = await DbHelper.open();
    DateTime now = DateTime.now();
    int timestampInMilliseconds = now.millisecondsSinceEpoch;
    updateTime = timestampInMilliseconds;
    await db.update(tableName, toMap(), where: 'id = $id');
    return this;
  }

  static bool _isInit = false;

  static Future<Database> _init() async {
    final db = await DbHelper.open();

    if (_isInit) {
      return db;
    }

    var tables = await DbHelper.getAllTables();

    if (tables.contains(tableName)) {
      _isInit = true;
      return db;
    }

    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tableName (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        platform TEXT NOT NULL,
        cover TEXT,
        relationId TEXT,
        relationUserId TEXT,
        relationAlbumId TEXT,
        userId INT,
        type TEXT,
        albumName TEXT,
        artist TEXT,
        local TEXT,
        audioTrack TEXT,
        extra TEXT,
        lyric TEXT,
        mimeType TEXT,
        updateTime INT NOT NULL,
        createTime INT NOT NULL
      )
    ''');

    _isInit = true;

    return db;
  }

  static Future<int> insert(MediaDbModel media) async {
    final db = await _init();
    if (media.cover.startsWith('http')) {
      var file = await Tool.cacheImg(
        url: media.cover,
        cacheKey: media.cacheKey,
        referer: media.extra.referer,
      );
      var coverpath = await Tool.getCoverStorePath();
      var name = file.path.split('/').last;
      await file.copy('$coverpath/$name');
      media.cover = '$coverpath/$name';
    }
    final map = media.toMap();
    map['id'] = null;
    return db.insert(
      tableName,
      map,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<List<MediaDbModel>> songs() async {
    final db = await _init();
    final List<Map<String, dynamic>> list = await db.query(
      tableName,
      where: 'type = ?',
      whereArgs: [MediaTagType.muisc.name],
    );
    return list.map((json) => MediaDbModel.fromMap(json)).toList();
  }

  static Future<int> getSongCount() async {
    final db = await _init();
    List<Map<String, dynamic>> result = await db.query(
      tableName,
      where: 'type = ?',
      whereArgs: [MediaTagType.muisc],
      columns: ['COUNT(*) as count'],
    );
    return result.first['count'];
  }

  static Future<List<MediaDbModel>> findByIds(List<int> ids) async {
    final db = await _init();
    String whereClause =
        'id IN (${List.generate(ids.length, (index) => '?').join(',')})';
    List<dynamic> whereArgs = List<dynamic>.from(ids);
    List<Map<String, dynamic>> list = await db.query(
      tableName,
      where: whereClause,
      whereArgs: whereArgs,
    );
    return list.map((json) => MediaDbModel.fromMap(json)).toList();
  }

  static Future<List<MediaDbModel>> findByRelationAlbumId({
    required List<String> ids,
    required MediaPlatformType platform,
    required MediaTagType type,
  }) async {
    final db = await _init();
    String whereClause =
        'relationAlbumId IN (${List.generate(ids.length, (index) => '?').join(',')})';
    List<dynamic> whereArgs = List<dynamic>.from(ids);

    whereClause += ' AND platform = ?';
    whereArgs.add(platform.name);

    whereClause += ' AND type = ?';
    whereArgs.add(type.name);

    List<Map<String, dynamic>> list = await db.query(
      tableName,
      where: whereClause,
      whereArgs: whereArgs,
    );
    return list.map((json) => MediaDbModel.fromMap(json)).toList();
  }

  static Future<List<MediaDbModel>> findByRelationIds({
    required List<String> ids,
    required MediaPlatformType platform,
    required MediaTagType type,
  }) async {
    final db = await _init();
    String whereClause =
        'relationId IN (${List.generate(ids.length, (index) => '?').join(',')})';
    List<dynamic> whereArgs = List<dynamic>.from(ids);

    whereClause += ' AND platform = ?';
    whereArgs.add(platform.name);

    whereClause += ' AND type = ?';
    whereArgs.add(type.name);

    List<Map<String, dynamic>> list = await db.query(
      tableName,
      where: whereClause,
      whereArgs: whereArgs,
    );
    return list.map((json) => MediaDbModel.fromMap(json)).toList();
  }

  static Future<List<MediaDbModel>> findByPlatform({
    required MediaPlatformType platform,
    required MediaTagType type,
  }) async {
    final db = await _init();

    var whereClause = 'platform = ? AND type = ?';
    var whereArgs = [platform.name, type.name];

    List<Map<String, dynamic>> list = await db.query(
      tableName,
      where: whereClause,
      whereArgs: whereArgs,
    );
    return list.map((json) => MediaDbModel.fromMap(json)).toList();
  }
}

class MediaDbExtraModel {
  late String referer;

  late String source = '';

  late String resourceId = '';

  MediaDbExtraModel({
    this.referer = '',
    this.source = '',
    this.resourceId = '',
  });

  static MediaDbExtraModel format(String? json) {
    if (json == null) {
      return MediaDbExtraModel();
    }
    try {
      var map = jsonDecode(json);
      var model = MediaDbExtraModel(
        referer: map['referer'] ?? '',
        resourceId: map['resourceId'] ?? '',
        source: json,
      );
      return model;
    } catch (e) {
      return MediaDbExtraModel();
    }
  }

  Map toMap() {
    return {"referer": referer, 'resourceId': resourceId};
  }

  @override
  String toString() {
    return jsonEncode(toMap());
  }
}
