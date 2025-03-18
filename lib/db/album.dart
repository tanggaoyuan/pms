import 'dart:convert';

import 'package:pms/components/export.dart';
import 'package:pms/db/export.dart';
import 'package:pms/utils/db.dart';
import 'package:pms/utils/export.dart';
import 'package:sqflite/sqflite.dart';

import '../apis/export.dart';

class AlbumDbModel {
  static String tableName = 'album';

  late int id;
  late String cover;
  late String name;
  late MediaPlatformType platform;
  late MediaTagType type;
  late int count;
  late String extra;
  late List<int> songIds;
  late int isSelf;

  /// 关联的平台的id
  late String relationId;
  late String relationUserId;
  late int userId;
  late int updateTime;
  late int createTime;

  AlbumDbModel({
    required this.name,
    required this.platform,
    required this.type,
    required this.isSelf,
    this.relationId = '',
    this.relationUserId = '',
    this.id = -1,
    this.cover = '',
    this.count = 0,
    this.userId = -1,
    this.extra = '',
    this.songIds = const [],
    int? updateTime,
    int? createTime,
  }) {
    DateTime now = DateTime.now();
    int timestampInMilliseconds = now.millisecondsSinceEpoch;
    this.createTime = createTime ?? timestampInMilliseconds;
    this.updateTime = updateTime ?? timestampInMilliseconds;
  }

  bool get isLocalMainAlbum {
    return relationId == MediaPlatformType.local.name;
  }

  bool get isLocalPlatform {
    return platform == MediaPlatformType.local;
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

  static AlbumDbModel createAlbumAction = AlbumDbModel(
    name: '创建专辑',
    platform: MediaPlatformType.action,
    type: MediaTagType.action,
    cover: ImgCompIcons.albumPlus,
    isSelf: 0,
  );

  static AlbumDbModel importAlbumAction = AlbumDbModel(
    name: '导入专辑',
    platform: MediaPlatformType.action,
    type: MediaTagType.action,
    cover: ImgCompIcons.importFile,
    isSelf: 0,
  );

  Future<AlbumDbModel> update() async {
    var db = await DbHelper.open();
    DateTime now = DateTime.now();
    int timestampInMilliseconds = now.millisecondsSinceEpoch;
    updateTime = timestampInMilliseconds;
    await db.update(tableName, toMap(), where: 'id = $id');
    return this;
  }

  static AlbumDbModel fromMap(Map<String, dynamic> json) {
    List ids = jsonDecode(json['songIds']);
    var songIds = ids.cast<int>();
    return AlbumDbModel(
      id: json['id'],
      cover: json['cover'],
      name: json['name'],
      type: MediaTagType.values.firstWhere((type) => type.toString().contains(json['type'])),
      platform: MediaPlatformType.values.firstWhere((type) => type.toString().contains(json['platform'])),
      updateTime: json['updateTime'],
      createTime: json['createTime'],
      relationId: json['relationId'],
      userId: json['userId'],
      count: songIds.isNotEmpty ? songIds.length : json['count'],
      extra: json['extra'] ?? '',
      songIds: songIds,
      relationUserId: json['relationUserId'] ?? '',
      isSelf: json['isSelf'],
    );
  }

  static AlbumDbModel fromAliFie(UserDbModel user, AliFile model, MediaTagType type) {
    return AlbumDbModel(
      name: model.name,
      platform: MediaPlatformType.aliyun,
      type: type,
      relationId: model.fileId,
      userId: user.id,
      relationUserId: user.relationId,
      isSelf: 1,
    );
  }

  static AlbumDbModel fromNetease(UserDbModel user, NetAlbum model) {
    return AlbumDbModel(
      name: model.name,
      platform: MediaPlatformType.netease,
      type: MediaTagType.muisc,
      relationId: model.id.toString(),
      cover: model.cover,
      count: model.count,
      userId: user.id,
      relationUserId: user.relationId,
      isSelf: 1,
    );
  }

  static AlbumDbModel fromBili(UserDbModel user, BliAlbum model, MediaTagType type) {
    return AlbumDbModel(
      name: model.title,
      platform: MediaPlatformType.bili,
      type: type,
      relationId: model.id.toString(),
      cover: model.cover,
      count: model.count,
      userId: user.id,
      extra: model.type.toString(),
      relationUserId: user.relationId,
      isSelf: user.relationId == model.userId.toString() ? 1 : 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      "id": id,
      "name": name,
      "type": type.name,
      "cover": cover,
      "platform": platform.name,
      "updateTime": updateTime,
      "createTime": createTime,
      "relationId": relationId,
      "userId": userId,
      'count': count,
      "extra": extra,
      "songIds": jsonEncode(songIds),
      "isSelf": isSelf,
      "relationUserId": relationUserId,
    };
  }

  @override
  String toString() {
    return jsonEncode(toMap());
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
        type TEXT,
        cover TEXT,
        relationId TEXT,
        relationUserId TEXT,
        songIds TEXT,
        count INT,
        userId INT,
        isSelf INT,
        extra TEXT,
        updateTime INT NOT NULL,
        createTime INT NOT NULL
      )
    ''');

    var music = AlbumDbModel(
      name: '本地音乐',
      id: -1,
      relationId: MediaPlatformType.local.name,
      platform: MediaPlatformType.local,
      type: MediaTagType.muisc,
      cover: ImgCompIcons.localMusic,
      isSelf: 1,
    );

    var video = AlbumDbModel(
      name: '本地视频',
      id: -2,
      relationId: MediaPlatformType.local.name,
      platform: MediaPlatformType.local,
      type: MediaTagType.video,
      cover: ImgCompIcons.localVideo,
      isSelf: 1,
    );

    await db.insert(
      tableName,
      music.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    await db.insert(
      tableName,
      video.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    _isInit = true;

    return db;
  }

  Future<int> remove() async {
    final db = await _init();
    return db.delete(tableName, where: 'id = $id');
  }

  static Future<int> insert(AlbumDbModel model) async {
    final db = await _init();
    final map = model.toMap();
    map.remove('id');
    var id = await db.insert(
      tableName,
      map,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return id;
  }

  static Future<void> batchInsert(List<AlbumDbModel> models) async {
    final db = await _init();
    return db.transaction((txn) async {
      var batch = txn.batch();
      for (var model in models) {
        batch.insert(
          tableName,
          model.toMap(),
        );
      }
      await batch.commit(noResult: true);
    });
  }

  static Future<int> delete(int? id) async {
    if (id == null) {
      return -1;
    }
    final db = await _init();
    return db.delete(tableName, where: 'id = $id');
  }

  static Future<List<AlbumDbModel>> albums(MediaTagType type) async {
    final db = await _init();
    final List<Map<String, dynamic>> list = await db.query(tableName, where: 'type = ?', whereArgs: [type.name]);
    return list.map((json) => AlbumDbModel.fromMap(json)).toList();
  }

  static Future<List<AlbumDbModel>> findByRelationIds({required List<String> ids, required MediaTagType type, MediaPlatformType? platform}) async {
    final db = await _init();
    String whereClause = 'relationId IN (${List.generate(ids.length, (index) => '?').join(',')})';
    List<dynamic> whereArgs = List<dynamic>.from(ids);

    whereClause += ' AND type = ?';
    whereArgs.add(type.name);

    if (platform != null) {
      whereClause += ' AND platform = ?';
      whereArgs.add(platform.name);
    }

    List<Map<String, dynamic>> list = await db.query(
      tableName,
      where: whereClause,
      whereArgs: whereArgs,
    );
    return list.map((json) => AlbumDbModel.fromMap(json)).toList();
  }

  static Future<List<AlbumDbModel>> findByIds(List<int> ids) async {
    final db = await _init();
    String whereClause = 'id IN (${List.generate(ids.length, (index) => '?').join(',')})';
    List<dynamic> whereArgs = List<dynamic>.from(ids);
    List<Map<String, dynamic>> list = await db.query(
      tableName,
      where: whereClause,
      whereArgs: whereArgs,
    );
    return list.map((json) => AlbumDbModel.fromMap(json)).toList();
  }
}
