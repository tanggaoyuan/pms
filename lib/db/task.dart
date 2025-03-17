import 'dart:convert';

import 'package:pms/db/export.dart';
import 'package:sqflite/sqflite.dart';

import '../utils/export.dart';

class TaskDbModel {
  static String tableName = 'task';

  late int id;
  late MediaTaskType type;
  late MediaPlatformType platform;
  late MediaTaskStatus status;
  late int mediaId;
  late String extra;
  late String remark;
  late int loaded;
  late int total;
  late int uploadAlbumId;
  late int updateTime;
  late int createTime;

  TaskDbModel({
    this.id = -1,
    required this.type,
    required this.platform,
    required this.status,
    required this.total,
    required this.loaded,
    required this.mediaId,
    this.remark = '',
    this.uploadAlbumId = -1,
    this.extra = '',
    int? updateTime,
    int? createTime,
  }) {
    DateTime now = DateTime.now();
    int timestampInMilliseconds = now.millisecondsSinceEpoch;
    this.createTime = createTime ?? timestampInMilliseconds;
    this.updateTime = updateTime ?? timestampInMilliseconds;
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

  int get progress {
    if (total == 0) {
      return 0;
    }
    return (loaded / total * 100).round();
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
        type TEXT NOT NULL,
        platform TEXT NOT NULL,
        status TEXT NOT NULL,
        mediaId INT NOT NULL,
        total INT NOT NULL,
        loaded INT NOT NULL,
        uploadAlbumId INT,
        extra TEXT,
        remark TEXT,
        updateTime INT NOT NULL,
        createTime INT NOT NULL
      )
    ''');

    _isInit = true;
    return db;
  }

  @override
  toString() {
    return jsonEncode(toMap());
  }

  static TaskDbModel fromMap(Map<String, dynamic> map) {
    return TaskDbModel(
      id: map['id'],
      type: MediaTaskType.values.firstWhere((e) => e.toString().contains(map['type'])),
      platform: MediaPlatformType.values.firstWhere((e) => e.toString().contains(map['platform'])),
      loaded: map['loaded'] ?? 0,
      total: map['total'] ?? 0,
      status: MediaTaskStatus.values.firstWhere((item) => item.toString().contains(map['status'])),
      extra: map['extra'],
      mediaId: map['mediaId'],
      updateTime: map['updateTime'],
      createTime: map['createTime'],
      uploadAlbumId: map['uploadAlbumId'],
      remark: map['remark'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.name,
      'platform': platform.name,
      'loaded': loaded,
      'total': total,
      'mediaId': mediaId,
      'status': status.name,
      'extra': extra,
      'updateTime': updateTime,
      'createTime': createTime,
      'uploadAlbumId': uploadAlbumId,
      'remark': remark,
    };
  }

  static Future<int> insert(TaskDbModel task) async {
    final db = await _init();
    final map = task.toMap();
    map['id'] = null;
    return db.insert(
      tableName,
      map,
    );
  }

  Future<int> remove() {
    return TaskDbModel.delete(id);
  }

  Future<TaskDbModel> update() async {
    var db = await DbHelper.open();
    DateTime now = DateTime.now();
    int timestampInMilliseconds = now.millisecondsSinceEpoch;
    updateTime = timestampInMilliseconds;
    await db.update(tableName, toMap(), where: 'id = $id');
    return this;
  }

  static Future<List<TaskDbModel>> tasks() async {
    final db = await _init();
    final List<Map<String, dynamic>> list = await db.query(tableName);
    return list.map((json) => TaskDbModel.fromMap(json)).toList();
  }

  static Future<List<TaskDbModel>> findByRelationIdAndPlatform(String relationId, MediaPlatformType platform) async {
    final db = await _init();
    final result = await db.query(tableName, where: 'relationId = ? AND platform = ?', whereArgs: [relationId, platform.toString()]);
    return result.map(TaskDbModel.fromMap).toList();
  }

  static Future<int> delete(int? id) async {
    if (id == null) {
      return -1;
    }
    final db = await _init();
    return db.delete(tableName, where: 'id = $id');
  }
}
