import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto;
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:encrypt/encrypt.dart';
import 'package:pms/utils/export.dart';
import 'package:pointycastle/export.dart';
import 'package:convert/convert.dart';

var _chain = DioChain(
  headers: {
    "Referer": "https://music.163.com/",
    "origin": "https://music.163.com",
    "sec-ch-ua":
        '"Microsoft Edge";v="131", "Chromium";v="131", "Not_A Brand";v="24"',
    "sec-ch-ua-mobile": "?0",
    "sec-ch-ua-platform": '"Windows"',
    "sec-fetch-dest": 'empty',
    "sec-fetch-mode": "cors",
    "sec-fetch-site": "same-origin",
  },
  baseUrl: 'https://music.163.com/eapi',
  interceptor: (chain) async {
    var baseUrl = chain.options.baseUrl;
    var isWeapi = baseUrl.contains('weapi') || chain.url.contains('weapi');
    var isEapi =
        (baseUrl.contains('eapi') || chain.url.contains('eapi')) && !isWeapi;

    var body = chain.body ?? {};

    var cookieMap = Tool.parseCookie(chain.options.headers['cookie']);
    var csrfToken = cookieMap['__csrf'] ?? '';

    if (isWeapi && body is Map) {
      body = {...body, 'csrf_token': csrfToken};
      chain.body = NeteaseApi.encodeWeApi(body);
      chain.query({"csrf_token": csrfToken});
    }

    if (isEapi && body is Map) {
      int timestamp = DateTime.now().millisecondsSinceEpoch;
      int randomNum = Random().nextInt(1000);
      String formattedRandomNum = randomNum.toString().padLeft(4, '0');
      String requestId = '${timestamp}_$formattedRandomNum';
      var header = {
        'osver': cookieMap['osver'] ??
            'Microsoft-Windows-10-Professional-build-22631-64bit',
        'deviceId': cookieMap['deviceId'] ?? 'pms',
        'appver': cookieMap['appver'] ?? '3.0.18.203152',
        'os': cookieMap['os'] ?? 'pc',
        'versioncode': cookieMap['versioncode'] ?? '140',
        'mobilename': cookieMap['mobilename'] ?? 'pms',
        'buildver': cookieMap['buildver'] ??
            DateTime.now().millisecondsSinceEpoch.toString().substring(
                  0,
                  10,
                ),
        'resolution': cookieMap['resolution'] ?? '1920*1080',
        '__csrf': csrfToken,
        'channel': cookieMap['channel'],
        'requestId': requestId,
      };

      if (cookieMap['MUSIC_U'] != null) {
        header['MUSIC_U'] = cookieMap['MUSIC_U']!;
      }

      if (cookieMap['MUSIC_A'] != null) {
        header['MUSIC_A'] = cookieMap['MUSIC_A']!;
      }

      chain.setCookie(Tool.mapToCookieString(header));

      body['header'] = header;
      body['er'] = false;

      chain.body = NeteaseApi.encodeEapi('/api${chain.url}', body);
    }

    // 解密响应数据
    // return (Response response) async {
    //   return response;
    // };

    return null;
  },
).setUserAgent().headerFormUrlencoded();

class NeteaseApi {
  static Map<String, String> encodeWeApi(Map data) {
    const base62 =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    Uint8List randomKeyBytes = Uint8List.fromList(
      List.generate(16, (int index) {
        return base62.codeUnitAt(Random().nextInt(61));
      }),
    );

    var publicKeyPem =
        '-----BEGIN PUBLIC KEY-----\nMIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQDgtQn2JZ34ZC28NWYpAUd98iZ37BUrX/aKzmFbt7clFSs6sXqHauqKWqdtLkF2KexO40H1YTX8z2lSgBBOAxLsvaklV8k4cBFK9snQXE9/DDaFt6Rr7iVZMldczhC0JNgTz+SHXT6CBHuX3e9SdB1Ua44oncaTWz7OBGLbCiK45wIDAQAB\n-----END PUBLIC KEY-----';
    RSAAsymmetricKey rsaPublicKey = RSAKeyParser().parse(publicKeyPem);
    var publicKey = PublicKeyParameter<RSAPublicKey>(
      rsaPublicKey as RSAPublicKey,
    );

    final cipher = RSAEngine()..init(true, publicKey);
    var secretKeyUint8List = cipher.process(
      Uint8List.fromList(randomKeyBytes.reversed.toList()),
    );
    var encSecKey = secretKeyUint8List
        .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
        .join();

    String content = jsonEncode(data);

    final key = Key.fromUtf8('0CoJUm6Qyw8W8jud');
    final iv = IV.fromUtf8('0102030405060708');

    var encrypter = Encrypter(AES(key, mode: AESMode.cbc));
    var encode = encrypter.encrypt(content, iv: iv);

    encrypter = Encrypter(AES(Key(randomKeyBytes), mode: AESMode.cbc));
    encode = encrypter.encrypt(encode.base64, iv: iv);

    return {'encSecKey': encSecKey, 'params': encode.base64};
  }

  static Map encodeEapi(String url, Map params) {
    var content = jsonEncode(params);
    var message = 'nobody${url}use${content}md5forencrypt';
    var bytes = utf8.encode(message);
    var digest = md5.convert(bytes).toString();

    // 拼接字符串
    var data = '$url-36cd479b6b5-$content-36cd479b6b5-$digest';
    final key = Key.fromUtf8('e82ckenh8dichen8');
    final iv = IV.fromUtf8('');

    var encrypter = Encrypter(AES(key, mode: AESMode.ecb));
    var encodeData = encrypter.encrypt(data, iv: iv);

    final hexString = hex.encode(encodeData.bytes);

    return {'params': hexString.toUpperCase()};
  }

  static Map decodeEapi(String text) {
    var key = Key.fromUtf8('e82ckenh8dichen8');
    var iv = IV.fromUtf8('');
    var encrypter = Encrypter(AES(key, mode: AESMode.ecb));
    var decodeData = encrypter.decrypt(Encrypted.fromBase64(text), iv: iv);
    RegExp regExp = RegExp(r'(.*?)-36cd479b6b5-(.*?)-36cd479b6b5-(.*)');
    var match = regExp.firstMatch(decodeData);
    if (match != null) {
      var jsonData = match.group(2) ?? '';
      Map data = jsonDecode(jsonData);
      return data;
    } else {
      return {};
    }
  }

  static DioChainResponse<NetUser> getUser(String cookie) {
    var url = '/w/nuser/account/get';
    return _chain.post<Map>(url).setCookie(cookie).format(NetUser.fromResponse);
  }

  static DioChainResponse<List<NetAlbum>> getPlaylist({
    required String cookie,
    required String userId,
  }) {
    var url = '/user/playlist';
    return _chain
        .post<String>(url)
        .send({"uid": userId, 'limit': 1000, 'offset': 0})
        .setCookie(cookie)
        .format(NetAlbum.fromResponse);
  }

  static DioChainResponse<List<NetSong>> getAlbumSongs({
    required String id,
    required String cookie,
    int limit = 100000,
  }) {
    var url = '/v6/playlist/detail';
    return _chain
        .post<String>(url)
        .send({"id": id, "n": limit, "s": 8})
        .setCookie(cookie)
        .format(NetSong.fromResponse);
  }

  static DioChainResponse<String> getPlayLink({
    required String id,
    required String cookie,
  }) {
    var url = "/song/enhance/player/url/v1";
    return _chain
        .post<String>(url)
        .send({
          "ids": jsonEncode([id]),
          "encodeType": 'flac',
          "level": "lossless",
        })
        .setLocalCache(2 * 60 * 60 * 1000, true)
        .setCookie(cookie)
        .format((response) {
          var json = jsonDecode(response.data ?? '');
          var map = FormatMap(json);
          return map
              .getString(['data', 0, 'url']).replaceAll('http://', 'https://');
        });
  }

  static DioChainResponse<NetSongPageInfo> getCloudSong({
    required String cookie,
    int offset = 0,
    int limit = 100,
  }) {
    var url = "/v1/cloud/get";
    return _chain
        .post<String>(url)
        .send({"limit": limit, "offset": offset})
        .setCookie(cookie)
        .format(NetSongPageInfo.fromResponse);
  }

  static DioChainResponse<ResponseBody> download({
    required String url,
    String? referer,
  }) {
    return _chain.getStream(url).setHeaders({"Connection": "keep-alive"},
        false).setExtra({'encode': false}).setReferer(referer);
  }

  static DioChainResponse deleteSong({
    required String cookie,
    required String albumId,
    required List<String> tracks,
  }) {
    var url = "/playlist/manipulate/tracks";
    return _chain.post(url).send({
      "pid": int.parse(albumId),
      "op": "del",
      "imme": 'true',
      "trackIds": jsonEncode(
        tracks.map((id) {
          return int.parse(id);
        }).toList(),
      ),
    }).setCookie(cookie);
  }

  static DioChainResponse deleteCloudSong({
    required String cookie,
    required List<String> tracks,
  }) {
    var url = "/cloud/del";
    return _chain.post(url).send({
      "songIds": jsonEncode(
        tracks.map((id) {
          return int.parse(id);
        }).toList(),
      ),
    }).setCookie(cookie);
  }

  static DioChainResponse<NetUploadFile> uploadCheck({
    required String cookie,
    required String filepath,
  }) {
    var file = NetUploadFile(filepath);
    var url = '/cloud/upload/check';
    return _chain
        .post<String>(url)
        .send({
          'bitrate': '999000',
          'ext': '',
          'length': file.fileSize,
          'md5': file.md5,
          'songId': '0',
          'version': 1,
        })
        .setCookie(cookie)
        .format((response) {
          var json = jsonDecode(response.data ?? '');
          var map = FormatMap(json);
          file.needUpload = map.getBool(['needUpload']);
          file.songId = map.getString(['songId']);
          return file;
        });
  }

  static DioChainResponse<NetUploadFile> uploadCreate({
    required String cookie,
    required NetUploadFile file,
  }) {
    const bucket = 'jd-musicrep-privatecloud-audio-public';
    var url = '/nos/token/alloc';
    return _chain
        .post<String>(url)
        .send({
          'bucket': bucket,
          'ext': file.ext,
          'filename': file.name,
          'local': false,
          'nos_product': 3,
          'type': 'audio',
          'md5': file.md5,
        })
        .setCookie(cookie)
        .format((response) {
          var json = jsonDecode(response.data ?? '');

          var map = FormatMap(json['result']);

          file.objectKey = map.getString(['objectKey']);
          file.token = map.getString(['token']);
          file.bucket = map.getString(['bucket']);
          file.resourceId = map.getInt(['resourceId']);
          file.outerUrl = map.getString(['outerUrl']);
          file.docId = map.getInt(['docId']);

          Tool.log(json['result']);

          return file;
        });
  }

  static DioChainResponse<List<String>> getUploadDomains() {
    const bucket = 'jd-musicrep-privatecloud-audio-public';
    var url = 'https://wanproxy.127.net/lbs?version=1.0&bucketname=$bucket';
    return _chain.get(url).format((response) {
      List ds = response.data['upload'];
      return ds.cast<String>();
    });
  }

  static DioChainResponse upload({
    required String cookie,
    required NetUploadFile file,
    required String domain,
  }) {
    const bucket = 'jd-musicrep-privatecloud-audio-public';
    var url =
        '$domain/$bucket/${file.objectKey}?offset=0&complete=true&version=1.0';
    var chunk = file.getChunk();
    return _chain.post(url, data: chunk).setHeaders({
      'x-nos-token': file.token,
      'Content-MD5': file.md5,
      'Content-Type': file.mimetype,
      'Content-Length': file.fileSize,
    }).setCookie(cookie);
  }

  static DioChainResponse<int> uploadFileSave({
    required String cookie,
    required NetUploadFile file,
  }) {
    var url = '/upload/cloud/info/v2';
    return _chain
        .post(url)
        .send({
          'bucket': file.bucket,
          'token': file.token,
          // 'objectKey': file.objectKey,
          'resourceId': file.resourceId,
          'docId': file.docId,
          'outerUrl': file.outerUrl,
          'md5': file.md5,
          'songid': file.songId,
          'filename': file.filename,
          'song': file.name,
          'album': '未知专辑',
          'artist': '未知艺术家',
          'bitrate': '999000',
          'objectKey': '${file.bucket}/${file.objectKey}',
        })
        .setCookie(cookie)
        .format((response) {
          var json = jsonDecode(response.data ?? '');
          var map = FormatMap(json);
          return map.getInt(['privateCloud', 'simpleSong', 'id']);
        });
  }

  static DioChainResponse uploadPublic({
    required String cookie,
    required int songId,
  }) {
    var url = '/cloud/pub/v2';
    return _chain.post(url).send({'songid': songId}).setCookie(cookie);
  }

  static DioChainResponse logout(String cookie) {
    var url = '/logout';
    return _chain.post(url).setCookie(cookie);
  }

  static DioChainResponse<NetSongPageInfo> search({
    required String keyword,
    String? cookie,
    int limit = 100,
    int offset = 0,
  }) {
    var url = '/search/get';
    return _chain
        .post(url)
        .send({'s': keyword, 'type': 1, 'limit': limit, 'offset': offset})
        .setCookie(cookie ?? "")
        .format(NetSongPageInfo.fromResponse);
  }

  static DioChainResponse<NetLrc> getLyric(int id) {
    var url = '/song/lyric';
    return _chain.post<String>(url).send({
      'id': id,
      'tv': -1,
      'lv': -1,
      'rv': -1,
      'kv': -1,
      '_nmclfl': 1
    }).format(NetLrc.fromResponse);
  }
}

class NetLrc {
  late String mainLrc;
  late String translateLrc;
  late String romaLrc;

  NetLrc({
    required this.mainLrc,
    required this.translateLrc,
    required this.romaLrc,
  });

  static NetLrc fromResponse(Response response) {
    var result = jsonDecode(response.data ?? '');
    var map = FormatMap(result);
    return NetLrc(
      mainLrc: map.getString(['lrc', 'lyric']),
      translateLrc: map.getString(['tlyric', 'lyric']),
      romaLrc: map.getString(['romalrc', 'lyric']),
    );
  }

  static NetLrc fromJson(String json) {
    try {
      var map = jsonDecode(json);
      return NetLrc(
        mainLrc: map['mainLrc'],
        translateLrc: map['translateLrc'],
        romaLrc: map['romaLrc'],
      );
    } catch (e) {
      return NetLrc(mainLrc: '', translateLrc: '', romaLrc: '');
    }
  }

  Map toMap() {
    return {
      'mainLrc': mainLrc,
      'translateLrc': translateLrc,
      'romaLrc': romaLrc,
    };
  }

  @override
  String toString() {
    return jsonEncode(toMap());
  }
}

class NetUploadFile {
  late File file;
  late String name;
  late String ext;
  late String filename;
  late String mimetype;
  late int fileSize;
  late bool needUpload;
  late String md5;
  late String songId;
  late int resourceId;
  late String bucket;
  late String token;
  late String objectKey;
  late String outerUrl;
  late int docId;

  NetUploadFile(String filepath) {
    file = File(filepath);
    fileSize = file.lengthSync();
    filename = filepath.split('/').last;
    var [name_, ext_] = filename.split('.');
    name = name_;
    ext = ext_;
    mimetype = filename.contains('.mp3') ? 'audio/mpeg' : 'audio/x-flac';
    md5 = getMd5(file);
    songId = '';
    resourceId = -1;
    bucket = '';
    objectKey = '';
    token = '';
    needUpload = true;
    outerUrl = '';
    docId = -1;
  }

  static String getMd5(File file) {
    var digestSink = AccumulatorSink<crypto.Digest>();
    var md5Sink = crypto.md5.startChunkedConversion(digestSink);
    var fileStream = file.openSync();
    var buffer = Uint8List(1024 * 1024); // 1MB 缓冲区大小
    int bytesRead;
    while ((bytesRead = fileStream.readIntoSync(buffer)) != 0) {
      md5Sink.add(buffer.sublist(0, bytesRead));
    }
    md5Sink.close();
    fileStream.closeSync();
    return digestSink.events.single.toString();
  }

  Stream<List<int>> getChunk() {
    return file.openRead();
  }
}

class NetSongPageInfo {
  late int count;
  late int size;
  late bool hasMore;
  late List<NetSong> songs;

  NetSongPageInfo({
    required this.count,
    required this.size,
    required this.hasMore,
    required this.songs,
  });

  static NetSongPageInfo fromResponse(Response response) {
    var json = jsonDecode(response.data);
    var map = FormatMap(json);

    var list =
        map.getList(['data'], map.getList(['result', 'songs'])).cast<Map>();

    return NetSongPageInfo(
      count: map.getInt(['count'], map.getInt(['result', 'songCount'])),
      size: map.getInt(['size']),
      hasMore: map.getBool(['hasMore'], map.getBool(['result', 'hasMore'])),
      songs: list.map(NetSong.fromCloudSong).toList(),
    );
  }
}

class NetSong {
  final int id;
  final String name;
  final String cover;
  final int userId;
  final int updateTime;
  final List<String> alia;
  final int fee;
  final String albumName;
  final bool isCloud;

  NetSong({
    required this.id,
    required this.name,
    required this.cover,
    required this.userId,
    required this.updateTime,
    required this.alia,
    this.fee = 0,
    this.albumName = '未知',
    this.isCloud = false,
  });

  Map<String, dynamic> toMap() {
    return {
      "id": id,
      "name": name,
      "cover": cover,
      "userId": userId,
      "alia": alia,
      "fee": fee,
      "albumName": albumName,
      "updateTime": updateTime,
      "isCloud": isCloud,
    };
  }

  static NetSong fromCloudSong(Map json) {
    var map = FormatMap(json);
    return NetSong(
      id: map.getInt(['id'], map.getInt(['simpleSong', 'id'])),
      name: map.getString(['name'], map.getString(['simpleSong', 'name'])),
      cover: map.getString([
        'album',
        'artist',
        'img1v1Url',
      ], map.getString(['simpleSong', 'al', 'picUrl'])),
      userId: 0,
      updateTime: map.getInt([
        'publishTime',
      ], map.getInt(['simpleSong', 'publishTime'])),
      alia: map.getList<String>([
        'alias',
      ], map.getList<String>(['simpleSong', 'alia'])),
      fee: map.getInt(['fee'], map.getInt(['simpleSong', 'fee'])),
      albumName: map.getString([
        'album',
        'name',
      ], map.getString(['simpleSong', 'album'])),
      isCloud: true,
    );
  }

  static List<NetSong> fromResponse(Response response) {
    var json = jsonDecode(response.data);
    var map = FormatMap(json);

    var tracks = map.getList(['playlist', 'tracks']);

    return tracks.map((item) {
      List ars = item['ar'] ?? [];

      var info = FormatMap(item);
      return NetSong(
        id: info.getInt(['id']),
        name: info.getString(['name']),
        alia: info.getList<String>([
          'alia',
        ], ars.map((item) => item['name']).cast<String>().toList()),
        cover: info.getString(['al', 'picUrl']),
        userId: info.getInt(['userId']),
        updateTime: info.getInt(['updateTime']),
        fee: info.getInt(['fee']),
        albumName: info.getString(['al', 'name']),
      );
    }).toList();
  }
}

class NetUser {
  late String avatar;
  late String phone;
  late int userId;
  late String userName;

  NetUser({
    required this.avatar,
    required this.phone,
    required this.userId,
    required this.userName,
  });

  NetUser.empty() {
    avatar = '';
    phone = '';
    userId = -1;
    userName = '';
  }

  Map<String, dynamic> toMap() {
    return {
      "avatar": avatar,
      "phone": phone,
      "userId": userId,
      "userName": userName,
    };
  }

  static NetUser fromResponse(Response response) {
    var map = FormatMap(response.data);
    return NetUser(
      avatar: map.getString(['profile', 'avatarUrl']),
      userId: map.getInt(['profile', 'userId']),
      userName: map.getString([
        'profile',
        'nickname',
      ], map.getString(['profile', 'userName'])),
      phone: map.getString(['profile', 'userName']),
    );
  }
}

class NetAlbum {
  final int id;
  final String name;
  final String cover;
  final int userId;
  final int count;
  final int updateTime;

  NetAlbum({
    required this.id,
    required this.name,
    required this.cover,
    required this.userId,
    required this.count,
    required this.updateTime,
  });

  Map<String, dynamic> toMap() {
    return {
      "id": id,
      "name": name,
      "cover": cover,
      "userId": userId,
      "count": count,
      "updateTime": updateTime,
    };
  }

  static List<NetAlbum> fromResponse(Response response) {
    var json = jsonDecode(response.data);
    var map = FormatMap(json);
    var list = map.getList(['playlist']);

    return list.map((item) {
      var info = FormatMap(item);
      return NetAlbum(
        id: info.getInt(['id']),
        name: info.getString(['name']),
        cover: info.getString(['coverImgUrl']),
        userId: info.getInt(['userId']),
        count: info.getInt(['trackCount']),
        updateTime: info.getInt(['updateTime']),
      );
    }).toList();
  }
}
