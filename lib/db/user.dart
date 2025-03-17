import 'dart:convert';
import 'package:get/get.dart';
import 'package:pms/db/export.dart';
import 'package:pms/utils/export.dart';
import 'package:sqflite/sqflite.dart';

import '../apis/export.dart';

bool _isCheckRefreshBili = true;

class UserDbModel {
  static String tableName = 'user';

  late int id;

  /// 关联平台的userId
  late String relationId;
  late String name;
  late MediaPlatformType platform;
  late String cover;
  late String accessToken;
  late String refreshToken;
  late String expireTime;
  late UserDbExtraModel extra;
  late int updateTime;
  late int createTime;

  UserDbModel({
    required this.relationId,
    required this.name,
    required this.platform,
    this.accessToken = '',
    this.refreshToken = '',
    this.expireTime = '',
    this.id = -1,
    this.cover = '',
    String? extra,
    int? updateTime,
    int? createTime,
  }) {
    DateTime now = DateTime.now();
    int timestampInMilliseconds = now.millisecondsSinceEpoch;
    this.extra = UserDbExtraModel.format(extra);
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

  static UserDbModel formMap(Map<String, dynamic> json) {
    return UserDbModel(
      id: json['id'],
      relationId: json['relationId'],
      name: json['name'],
      platform: MediaPlatformType.values.firstWhere((item) => item.toString().contains(json['platform'])),
      cover: json['cover'],
      updateTime: json['updateTime'],
      createTime: json['createTime'],
      accessToken: json['accessToken'],
      refreshToken: json['refreshToken'],
      expireTime: json['expireTime'],
      extra: json['extra'],
    );
  }

  bool get isExpire {
    return DateTime.parse(expireTime).millisecondsSinceEpoch < DateTime.now().millisecondsSinceEpoch;
  }

  Future<UserDbModel> update() async {
    var db = await DbHelper.open();
    DateTime now = DateTime.now();
    int timestampInMilliseconds = now.millisecondsSinceEpoch;
    updateTime = timestampInMilliseconds;
    await db.update(tableName, toMap(), where: 'id = $id');
    return this;
  }

  Future<int> remove() async {
    var db = await DbHelper.open();
    return db.delete(
      tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<UserDbModel> updateToken() async {
    try {
      if (platform == MediaPlatformType.aliyun) {
        var xSignature = await AliyunApi.xSignature(
          privateKeyHex: extra.privateKeyHex,
          appId: extra.appId,
          xDeviceId: extra.xDeviceId,
          userId: relationId,
        );
        extra.xSignature = xSignature;

        if (isExpire) {
          var token = await AliyunApi.refreshToken(appId: extra.appId, refreshToken: refreshToken).enableMergeSame().getData();
          accessToken = token.accessToken;
          refreshToken = token.refreshToken;
          expireTime = token.expireTime;
          extra.referer = AliyunApi.deviceReferer;
          await update();
        }
      }

      if (platform == MediaPlatformType.bili) {
        var nowDate = DateTime.now();
        var wbiDate = DateTime.fromMillisecondsSinceEpoch(extra.wbiCreateTime);

        if (wbiDate.year != nowDate.year && wbiDate.month != nowDate.month && wbiDate.day != nowDate.day) {
          var ticket = await BiliApi.getTicket(accessToken).enableMergeSame().getData();
          accessToken = Tool.mapToCookieString({
            ...Tool.parseCookie(accessToken),
            'bili_ticket': ticket.ticket,
            'bili_ticket_expires': (ticket.createTime + ticket.expireTime).toString(),
          });
          extra.imgKey = ticket.imgKey;
          extra.subKey = ticket.subKey;
          extra.wbiCreateTime = nowDate.millisecondsSinceEpoch;

          // Tool.log(['更新wbi', ticket.toMap(), extra.toMap(), accessToken]);

          await update();
        }

        if (refreshToken.isEmpty) {
          return this;
        }

        if (!_isCheckRefreshBili) {
          return this;
        }

        var refreshTime = await BiliApi.getRefreshTime(accessToken).enableMergeSame().getData();

        _isCheckRefreshBili = false;

        if (refreshTime == 0) {
          return this;
        }

        var secret = BiliApi.generateSecret(refreshTime);

        var refreshCode = await BiliApi.getRefreshCode(secret: secret, cookie: accessToken).enableMergeSame().getData();

        var response = await BiliApi.getNewRefreshToken(refreshCode: refreshCode, cookie: accessToken, refreshToken: refreshToken).enableMergeSame();

        var newRefreshToken = response.data as String;

        var newCookies = response.headers['set-cookie'] as List<String>;

        var newCookie = '';

        for (var ck in newCookies) {
          newCookie += '${ck.split(';').first.trim()}; ';
        }

        Tool.log(newCookie);

        await BiliApi.disableToken(newCookie: newCookie, oldRefreshToken: refreshToken).enableMergeSame();

        refreshToken = newRefreshToken;
        accessToken = newCookie;
        await update();
      }
    } catch (e) {
      Tool.showConfirm(title: '提示'.tr, content: '${'更新凭证异常，请手动退出并重新登录'.tr} => ${platform.name} - $name', onConfirm: () async {});
      return this;
    }

    return this;
  }

  Map<String, dynamic> toMap() {
    return {
      "id": id,
      "relationId": relationId,
      "name": name,
      "cover": cover,
      "platform": platform.toString().split('.').last,
      "updateTime": updateTime,
      "createTime": createTime,
      'accessToken': accessToken,
      'refreshToken': refreshToken,
      'expireTime': expireTime,
      "extra": extra.toString(),
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
        relationId TEXT NOT NULL,
        name TEXT NOT NULL,
        platform TEXT NOT NULL,
        cover TEXT,
        accessToken TEXT,
        refreshToken TEXT,
        expireTime TEXT,
        extra TEXT,
        updateTime INT NOT NULL,
        createTime INT NOT NULL
      )
    ''');

    _isInit = true;
    return db;
  }

  static Future<UserDbModel> createAliyunUser(Map<String, dynamic> json) async {
    var xDeviceId = AliyunApi.generateRandomDeviceId();

    var map = FormatMap(json);

    var appId = map.getString(['app_id']);

    AliToken token = AliToken.fromMap(json);

    if (token.isExpire) {
      token = await AliyunApi.refreshToken(appId: appId, refreshToken: token.refreshToken).getData();
    }

    var result = await AliyunApi.generatePrivateKeyHex(
      xDeviceId: xDeviceId,
      userId: token.userId,
      token: token.accessToken,
      appId: appId,
    );

    var user = await AliyunApi.getUserInfo(token.accessToken).getData();

    var extra = {
      'privateKeyHex': result.first,
      'drive_id': user.resourceDriveId,
      'app_id': appId,
      'x_device_id': xDeviceId,
      'referer': AliyunApi.webReferer,
    };

    var model = UserDbModel(
      id: -1,
      relationId: user.userId,
      name: user.nickName.isEmpty ? user.userName : user.nickName,
      platform: MediaPlatformType.aliyun,
      cover: user.avatar,
      accessToken: token.accessToken,
      refreshToken: token.refreshToken,
      expireTime: token.expireTime,
      extra: jsonEncode(extra),
    );

    var id = await UserDbModel.insert(model);

    model.id = id;

    return model;
  }

  static Future<UserDbModel> createNeteaseUser(String cookie) async {
    var info = await NeteaseApi.getUser(cookie).getData();
    var model = UserDbModel(
      id: -1,
      relationId: '${info.userId}',
      name: info.userName,
      platform: MediaPlatformType.netease,
      cover: info.avatar,
      accessToken: cookie,
    );
    var id = await UserDbModel.insert(model);
    model.id = id;
    return model;
  }

  static Future<UserDbModel> createBiliUser(String refreshToken, String cookie) async {
    var info = await BiliApi.getUserInfo(cookie).getData();
    var model = UserDbModel(
      id: -1,
      relationId: '${info.userId}',
      name: info.userName,
      platform: MediaPlatformType.bili,
      cover: info.avatar,
      accessToken: cookie,
      refreshToken: refreshToken,
      extra: jsonEncode({
        "img_key": info.imgKey,
        "sub_key": info.subKey,
        "referer": "https://www.bilibili.com/",
        "wbi_create_time": DateTime.now().millisecondsSinceEpoch,
      }),
    );
    var id = await UserDbModel.insert(model);
    model.id = id;
    return model;
  }

  static Future<int> insert(UserDbModel user) async {
    final db = await _init();
    final map = user.toMap();
    map['id'] = null;
    return db.insert(
      tableName,
      map,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<List<UserDbModel>> findByRelationIds(List<String> ids, [MediaPlatformType? platform]) async {
    final db = await _init();
    String whereClause = 'relationId IN (${List.generate(ids.length, (index) => '?').join(',')})';
    List<dynamic> whereArgs = List<dynamic>.from(ids);

    if (platform != null) {
      whereClause += ' AND platform = ?';
      whereArgs.add(platform.name);
    }

    List<Map<String, dynamic>> list = await db.query(
      tableName,
      where: whereClause,
      whereArgs: whereArgs,
    );
    return list.map((json) => UserDbModel.formMap(json)).toList();
  }

  static Future<List<UserDbModel>> findByPlatform(MediaPlatformType platform) async {
    final db = await _init();
    List<Map<String, dynamic>> list = await db.query(
      tableName,
      where: 'platform = ?',
      whereArgs: [platform.name],
    );
    return list.map((json) => UserDbModel.formMap(json)).toList();
  }

  static Future<List<UserDbModel>> users() async {
    final db = await _init();
    final List<Map<String, dynamic>> list = await db.query(tableName);
    return list.map((json) => UserDbModel.formMap(json)).toList();
  }
}

class UserDbExtraModel {
  late String privateKeyHex;
  late String driveId;
  late String appId;
  late String xDeviceId;
  late String xSignature;
  late String referer;
  late String imgKey;
  late String subKey;
  late int wbiCreateTime;

  late String source = '';

  UserDbExtraModel({
    this.privateKeyHex = '',
    this.driveId = '',
    this.appId = '',
    this.xDeviceId = '',
    this.source = '',
    this.xSignature = '',
    this.referer = '',
    this.imgKey = '',
    this.subKey = '',
    this.wbiCreateTime = 0,
  });

  static UserDbExtraModel format(String? json) {
    if (json == null) {
      return UserDbExtraModel();
    }
    try {
      var map = FormatMap(jsonDecode(json));
      var model = UserDbExtraModel(
        privateKeyHex: map.getString(['privateKeyHex']),
        driveId: map.getString(['drive_id']),
        appId: map.getString(['app_id']),
        xDeviceId: map.getString(['x_device_id']),
        xSignature: map.getString(['x_signature']),
        referer: map.getString(['referer']),
        imgKey: map.getString(['img_key']),
        subKey: map.getString(['sub_key']),
        wbiCreateTime: map.getInt(['wbi_create_time']),
        source: json,
      );
      return model;
    } catch (e) {
      return UserDbExtraModel();
    }
  }

  Map toMap() {
    return {
      "privateKeyHex": privateKeyHex,
      "drive_id": driveId,
      "app_id": appId,
      "x_device_id": xDeviceId,
      "x_signature": xSignature,
      "referer": referer,
      "img_key": imgKey,
      "sub_key": subKey,
      "wbi_create_time": wbiCreateTime,
    };
  }

  @override
  String toString() {
    return jsonEncode(toMap());
  }
}
