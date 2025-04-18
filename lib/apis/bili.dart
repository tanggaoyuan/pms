import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:encrypt/encrypt.dart';
import 'package:pms/utils/dash_to_map.dart';
import 'package:pms/utils/export.dart';
import 'package:pointycastle/export.dart';

var _chain = DioChain(
  headers: {
    "Referer": "https://www.bilibili.com/",
    "origin": "https://www.bilibili.com",
    "sec-ch-ua":
        '"Microsoft Edge";v="131", "Chromium";v="131", "Not_A Brand";v="24"',
    "sec-ch-ua-mobile": "?0",
    "sec-ch-ua-platform": '"Windows"',
    "sec-fetch-dest": 'empty',
    "sec-fetch-mode": "cors",
    "sec-fetch-site": "same-site",
  },
  interceptor: (chain) async {
    var cookieMap = Tool.parseCookie(chain.options.headers['cookie']);
    var csrfToken = cookieMap['bili_jct'] ?? '';
    chain.query({"csrf": csrfToken});
    chain.send({"csrf": csrfToken});
    var extra = chain.extra;
    if (extra['imgKey'] is String && extra['subKey'] is String) {
      var wbiParams = BiliApi.encodeWbi(
        chain.options.queryParameters,
        extra['imgKey'],
        extra['subKey'],
      );
      chain.query(wbiParams);
    }
    return (Response response) async {
      var data = response.data;

      if (data is Map && data['code'] == -101) {
        throw response;
      }

      return response;
    };
  },
).setUserAgent();

class BiliApi {
  static DioChainResponse<int> getRefreshTime(String cookie) {
    var url = 'https://passport.bilibili.com/x/passport-login/web/cookie/info';
    return _chain.get(url).setCookie(cookie).format((response) {
      var map = FormatMap(response.data);
      var refresh = map.getBool(['data', 'refresh']);
      var timestamp = map.getInt(['data', 'timestamp']);
      return refresh ? timestamp : 0;
    });
  }

  static String generateSecret(int timestampe) {
    var publicKeyPem =
        "-----BEGIN PUBLIC KEY-----\nMIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQDLgd2OAkcGVtoE3ThUREbio0Eg\nUc/prcajMKXvkCKFCWhJYJcLkcM2DKKcSeFpD/j6Boy538YXnR6VhcuUJOhH2x71\nnzPjfdTcqMz7djHum0qSZA0AyCBDABUqCrfNgCiJ00Ra7GmRj+YCK1NJEuewlb40\nJNrRuoEUXpabUzGB8QIDAQAB\n-----END PUBLIC KEY-----";
    var publicKey = RSAKeyParser().parse(publicKeyPem) as RSAPublicKey;
    final encrypter = Encrypter(
      RSA(
        publicKey: publicKey,
        encoding: RSAEncoding.OAEP,
        digest: RSADigest.SHA256,
      ),
    );
    final encrypted = encrypter.encrypt('refresh_$timestampe');
    return encrypted.base16;
  }

  static DioChainResponse<String> getSecret(int refreshTime) {
    var url = 'https://wasm-rsa.vercel.app/api/rsa?t=$refreshTime';
    return _chain.get<Map>(url).setHeaders({}, false).format((response) {
      return response.data!['hash'];
    });
  }

  /// https://wasm-rsa.vercel.app/api/rsa?t=1684468084078
  static DioChainResponse<String> getRefreshCode({
    required String secret,
    required String cookie,
  }) {
    var url = 'https://www.bilibili.com/correspond/1';
    return _chain.get<String>('$url/$secret').setCookie(cookie).format((
      respone,
    ) {
      var content = respone.data;
      if (content is String) {
        final regExp = RegExp(r'<div\s+id="1-name">(.+?)</div>');
        final match = regExp.firstMatch(content);
        if (match != null) {
          return match.group(1) ?? '';
        }
      }
      return '';
    });
  }

  /// 获取到新的refreshToken 和 header新的cookie
  static DioChainResponse<String> getNewRefreshToken({
    required String refreshCode,
    required String cookie,
    required String refreshToken,
  }) {
    var url =
        'https://passport.bilibili.com/x/passport-login/web/cookie/refresh';
    return _chain
        .post<Map>(url)
        .query({
          "refresh_csrf": refreshCode,
          "source": "main_web",
          'refresh_token': refreshToken,
        })
        .setCookie(cookie)
        .format((response) {
          var map = FormatMap(response.data);
          return map.getString(['data', 'refresh_token']);
        });
  }

  /// 使旧的凭证失效
  /// 传入新获取的cookie 和 旧的refreshToken
  static DioChainResponse<Map> disableToken({
    required String newCookie,
    required String oldRefreshToken,
  }) {
    var url =
        'https://passport.bilibili.com/x/passport-login/web/confirm/refresh';
    return _chain
        .post<Map>(url)
        .query({'refresh_token': oldRefreshToken}).setCookie(newCookie);
  }

  static encodeWbi(Map<String, dynamic> params, String imgKey, String subKey) {
    const List<int> mixinKeyEncTab = [
      46,
      47,
      18,
      2,
      53,
      8,
      23,
      32,
      15,
      50,
      10,
      31,
      58,
      3,
      45,
      35,
      27,
      43,
      5,
      49,
      33,
      9,
      42,
      19,
      29,
      28,
      14,
      39,
      12,
      38,
      41,
      13,
      37,
      48,
      7,
      16,
      24,
      55,
      40,
      61,
      26,
      17,
      0,
      1,
      60,
      51,
      30,
      4,
      22,
      25,
      54,
      21,
      56,
      59,
      6,
      63,
      57,
      62,
      11,
      36,
      20,
      34,
      44,
      52,
    ];

    var secret = imgKey.split('/').last.split('.').first +
        subKey.split('/').last.split('.').first;

    StringBuffer buffer = StringBuffer();
    for (int n in mixinKeyEncTab) {
      buffer.write(secret[n]);
    }
    String mixkey = buffer.toString().substring(0, 32);

    int time = (DateTime.now().millisecondsSinceEpoch / 1000).floor();

    var data = {...params, "wts": time};

    List<String> queryList = data.keys.toList();

    queryList.sort((a, b) => a.compareTo(b));

    var query = queryList
        .map((key) {
          String value = data[key].toString().replaceAll(
                RegExp(r"[!\'()*]"),
                '',
              );
          return '${Uri.encodeComponent(key)}=${Uri.encodeComponent(value)}';
        })
        .toList()
        .join('&');

    Tool.log(query + mixkey);

    var sign = md5.convert(utf8.encode(query + mixkey)).toString();

    return {"wts": time, "w_rid": sign};
  }

  static DioChainResponse<BliTicket> getTicket(String cookie) {
    var ts = DateTime.now().millisecondsSinceEpoch / 1000;

    final keyBytes = utf8.encode('XgwSnGZ1p');
    final messageBytes = utf8.encode('ts$ts');

    final hmac = Hmac(sha256, keyBytes);
    final digest = hmac.convert(messageBytes);

    final hexSign = digest.bytes
        .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
        .join();

    var url =
        'https://api.bilibili.com/bapis/bilibili.api.ticket.v1.Ticket/GenWebTicket';

    return _chain.post<Map>(url).query({
      "key_id": 'ec02',
      "hexsign": hexSign,
      'context[ts]': ts
    }).format(BliTicket.fromResponse);
  }

  static DioChainResponse<BliUser> getUserInfo(String cookie) {
    var url = 'https://api.bilibili.com/x/web-interface/nav';
    return _chain.get(url).setCookie(cookie).format(BliUser.fromResponse);
  }

  static DioChainResponse<BliAlbumPageInfo> getFavFolder({
    required String userId,
    required String cookie,
    int limit = 20,
    int page = 1,
  }) {
    var url = 'https://api.bilibili.com/x/v3/fav/folder/created/list';
    return _chain
        .get(url)
        .query({
          "up_mid": int.parse(userId),
          "pn": page,
          "ps": limit,
          "platform": "web",
        })
        .format(BliAlbumPageInfo.fromResponse)
        .setCookie(cookie);
  }

  static DioChainResponse<BliAlbumPageInfo> getSubFolder({
    required String userId,
    required String cookie,
    int limit = 20,
    int page = 1,
  }) {
    var url = 'https://api.bilibili.com/x/v3/fav/folder/collected/list';

    return _chain
        .get(url)
        .query({
          "up_mid": int.parse(userId),
          "pn": page,
          "ps": limit,
          "platform": "web",
        })
        .format(BliAlbumPageInfo.fromResponse)
        .setCookie(cookie);
  }

  static DioChainResponse<BliVideoPageInfo> getFavVideos({
    required String mediaId,
    required String cookie,
    int page = 1,
    int limit = 20,
  }) {
    var url = 'https://api.bilibili.com/x/v3/fav/resource/list';
    return _chain
        .get(url)
        .query({
          "media_id": mediaId,
          "pn": page,
          "ps": limit,
          "keyword": null,
          "order": 'mtime',
          "type": 0,
          "tid": 0,
          "platform": "web",
        })
        .setCookie(cookie)
        .format(BliVideoPageInfo.fromResponse);
  }

  static DioChainResponse<BliVideoPageInfo> getSubVideos({
    required String seasonId,
    required String cookie,
    int page = 1,
    int limit = 20,
  }) {
    var url = 'https://api.bilibili.com/x/space/fav/season/list';
    return _chain
        .get(url)
        .query({"season_id": seasonId, "pn": page, "ps": limit})
        .setCookie(cookie)
        .format(BliVideoPageInfo.fromResponse);
  }

  static DioChainResponse<List<BliVideoSampleInfo>> getVideoSampleInfo({
    required String bvid,
    required String cookie,
  }) {
    var url = 'https://api.bilibili.com/x/player/pagelist';
    return _chain
        .get<Map>(url)
        .query({'bvid': bvid})
        .setCookie(cookie)
        .setLocalCache(double.infinity)
        .format(BliVideoSampleInfo.fromResponse);
  }

  static DioChainResponse<BliPlayInfo> getPlayInfo({
    required String bvid,
    required int cid,
    required String cookie,
    required String imgKey,
    required String subKey,
  }) {
    var url = 'https://api.bilibili.com/x/player/wbi/playurl';
    return _chain
        .get(url)
        .query({"bvid": bvid, "cid": cid, "qn": 112, "fnval": 16})
        .setExtra({"imgKey": imgKey, "subKey": subKey})
        .setCookie(cookie)
        .setLocalCache(10 * 60 * 1000)
        .format(BliPlayInfo.fromResponse);
  }

  static DioChainResponse<DashHelper> getPlayDash({
    required String bvid,
    required int cid,
    required String cookie,
    required String imgKey,
    required String subKey,
  }) {
    var url = 'https://api.bilibili.com/x/player/wbi/playurl';
    return _chain
        .get(url)
        .query({"bvid": bvid, "cid": cid, "qn": 112, "fnval": 16})
        .setExtra({"imgKey": imgKey, "subKey": subKey})
        .setCookie(cookie)
        .setLocalCache(10 * 60 * 1000)
        .format((response) {
          return DashHelper.formBili(response.data["data"]["dash"]);
        });
  }

  static DioChainResponse<BliAlbum> getAlbumInfo({
    required String cookie,
    required String mediaId,
  }) {
    var url = 'https://api.bilibili.com/x/v3/fav/folder/info';
    return _chain
        .get<Map>(url)
        .query({"media_id": mediaId})
        .setCookie(cookie)
        .format(BliAlbum.fromResponse);
  }

  static DioChainResponse<ResponseBody> download({
    required String url,
    required String referer,
  }) {
    return _chain
        .getStream(url)
        .setHeaders({"Connection": "keep-alive"}).setReferer(referer);
  }

  static deleteFavVideo({
    required String cookie,
    required String mediaId,
    required List<String> resources,
  }) {
    var url = 'https://api.bilibili.com/x/v3/fav/resource/batch-del';
    return _chain
        .post<Map>(url)
        .send({"resources": resources.join(','), "media_id": mediaId})
        .setCookie(cookie)
        .headerFormUrlencoded();
  }

  static logout(String cookie) {
    var url = 'https://passport.bilibili.com/login/exit/v2';
    var cookieMap = Tool.parseCookie(cookie);
    return _chain
        .post(url)
        .send({'biliCSRF': cookieMap['bili_jct']}).setCookie(cookie);
  }
}

class BliPlayInfo {
  late int quality;
  late String format;
  late int duration;
  late List<String> formatNames;
  late List<int> qualitys;
  late List<BliMediaInfo> videos;
  late List<BliMediaInfo> audios;

  BliPlayInfo({
    required this.quality,
    required this.format,
    required this.duration,
    required this.formatNames,
    required this.qualitys,
    required this.videos,
    required this.audios,
  });

  Map<String, dynamic> toMap() {
    return {
      "quality": quality,
      "format": format,
      "duration": duration,
      "formatNames": formatNames,
      "qualitys": qualitys,
      "videos": videos.map((video) => video.toMap()).toList(),
      "audios": audios.map((audio) => audio.toMap()).toList(),
    };
  }

  static BliPlayInfo fromResponse(Response response) {
    var map = FormatMap(response.data["data"]);
    return BliPlayInfo(
      quality: map.getInt(['quality']),
      format: map.getString(['format']),
      duration: map.getInt(['timelength']),
      formatNames: map.getList<String>(['accept_description']),
      qualitys: map.getList<int>(['accept_quality']),
      videos: map
          .getList(['dash', 'video'])
          .map((item) => BliMediaInfo.fromMap(item))
          .toList(),
      audios: map
          .getList(['dash', 'audio'])
          .map((item) => BliMediaInfo.fromMap(item))
          .toList(),
    );
  }
}

class BliMediaInfo {
  late int quality;
  late String url;
  late List<String> backupUrl;
  late String mimeType;
  late String codecs;
  late int width;
  late int height;
  late String fps;
  late Map segment;
  late int codecid;

  BliMediaInfo({
    required this.quality,
    required this.url,
    required this.backupUrl,
    required this.mimeType,
    required this.codecs,
    required this.width,
    required this.height,
    this.fps = '',
    this.segment = const {},
    this.codecid = 0,
  });

  static BliMediaInfo fromMap(Map json) {
    var map = FormatMap(json);

    return BliMediaInfo(
      quality: map.getInt(['id']),
      url: map.getString(['base_url']),
      backupUrl: map.getList<String>(['backup_url']),
      mimeType: map.getString(['mime_type']),
      codecs: map.getString(['codecs']),
      width: map.getInt(['width']),
      height: map.getInt(['height']),
      fps: map.getString(['frame_rate']),
      segment: map.getMap(['segment_base']),
      codecid: map.getInt(['codecid']),
    );
  }

  bool get isVideo {
    return mimeType.contains('video');
  }

  bool get isAudio {
    return mimeType.contains('audio');
  }

  Map<String, dynamic> toMap() {
    return {
      "quality": quality,
      "url": url,
      "backupUrl": backupUrl,
      "mimeType": mimeType,
      "codecs": codecs,
      "width": width,
      "height": height,
      "fps": fps,
      "segment": segment,
    };
  }
}

class BliVideoSampleInfo {
  late int cid;
  late int page;
  late String title;
  late int duration;
  late String vid;
  late Object dimension;
  late String cover;

  BliVideoSampleInfo({
    required this.cid,
    required this.page,
    required this.title,
    required this.cover,
    required this.dimension,
    required this.duration,
    required this.vid,
  });

  Map<String, dynamic> toMap() {
    return {
      "cid": cid,
      "page": page,
      "title": title,
      "cover": cover,
      "dimension": dimension,
      "duration": duration,
      "vid": vid,
    };
  }

  static BliVideoSampleInfo fromMap(Map json) {
    var map = FormatMap(json);
    return BliVideoSampleInfo(
      cid: map.getInt(['cid']),
      page: map.getInt(['page']),
      title: map.getString(['part']),
      dimension: map.getDynamic(['dimension']),
      vid: map.getString(['vid']),
      cover: map.getString(['first_frame']),
      duration: map.getInt(['duration']),
    );
  }

  static List<BliVideoSampleInfo> fromResponse(Response response) {
    var map = FormatMap(response.data);
    var list = map.getList(['data']);
    return list.map((item) => BliVideoSampleInfo.fromMap(item)).toList();
  }
}

class BliVideoPageInfo {
  late bool hasMore;
  late List<BliVideoInfo> medias;
  late int total;

  BliVideoPageInfo({
    required this.hasMore,
    required this.medias,
    required this.total,
  });

  Map<String, dynamic> toMap() {
    return {
      "hasMore": hasMore,
      "medias": medias.map((album) => album.toMap()).toList(),
      "total": total,
    };
  }

  static BliVideoPageInfo fromResponse(Response response) {
    var map = FormatMap(response.data);
    var list = map.getList(['data', 'medias']);
    var hasMore = map.getBool(['data', 'has_more'], false);
    return BliVideoPageInfo(
      hasMore: hasMore,
      medias: list.map((item) => BliVideoInfo.fromMap(item)).toList(),
      total: map.getInt(['data', 'info', 'media_count']),
    );
  }
}

class BliVideoInfo {
  late int attr;
  late int id;
  late String bvid;
  late String cover;
  late int duration;
  late String intro;
  late String title;
  late int type;
  late String upperCover;
  late int upperUserId;
  late String upperName;

  BliVideoInfo({
    required this.id,
    required this.bvid,
    required this.cover,
    required this.duration,
    required this.intro,
    required this.title,
    required this.type,
    required this.upperCover,
    required this.upperName,
    required this.upperUserId,
    required this.attr,
  });

  bool get isExpire {
    return attr == 1;
  }

  Map<String, dynamic> toMap() {
    return {
      "id": id,
      "bvid": bvid,
      "cover": cover,
      "duration": duration,
      "intro": intro,
      "title": title,
      "type": type,
      "upperCover": upperCover,
      "upperName": upperName,
      "upperUserId": upperUserId,
      "attr": attr,
    };
  }

  static BliVideoInfo fromMap(Map json) {
    var map = FormatMap(json);
    return BliVideoInfo(
      id: map.getInt(['id']),
      bvid: map.getString(['bvid']),
      cover: map.getString(['cover']),
      duration: map.getInt(['duration']),
      intro: map.getString(['intro']),
      title: map.getString(['title']),
      type: map.getInt(['type']),
      upperCover: map.getString(['upper', 'face']),
      upperName: map.getString(['upper', 'name']),
      upperUserId: map.getInt(['upper', 'mid']),
      attr: map.getInt(['attr']),
    );
  }
}

class BliAlbumPageInfo {
  late int total;
  late List<BliAlbum> albums;

  BliAlbumPageInfo({required this.total, required this.albums});

  Map<String, dynamic> toMap() {
    return {
      "total": total,
      "albums": albums.map((album) => album.toMap()).toList(),
    };
  }

  static BliAlbumPageInfo fromResponse(Response response) {
    var map = FormatMap(response.data);
    var list = map.getList(['data', 'list']);
    var total = map.getInt(['data', 'count']);
    return BliAlbumPageInfo(
      total: total,
      albums: list.map((item) => BliAlbum.fromMap(item)).toList(),
    );
  }
}

class BliAlbum {
  late int id;
  late int fid;
  late int userId;
  late String title;
  late String cover;
  late int count;
  late int type;

  BliAlbum({
    required this.id,
    required this.fid,
    required this.userId,
    required this.title,
    required this.cover,
    required this.count,
    required this.type,
  });

  Map<String, dynamic> toMap() {
    return {
      "id": id,
      "fid": fid,
      "userId": userId,
      "title": title,
      "cover": cover,
      "count": count,
      "type": type,
    };
  }

  static BliAlbum fromMap(Map<String, dynamic> map) {
    return BliAlbum(
      id: map['id'],
      fid: map['fid'],
      userId: map['mid'],
      title: map['title'],
      cover: map['cover'],
      count: map['media_count'],
      type: map['type'],
    );
  }

  static BliAlbum fromResponse(Response response) {
    var map = FormatMap(response.data);
    return BliAlbum(
      id: map.getInt(['data', 'id']),
      fid: map.getInt(['data', 'fid']),
      userId: map.getInt(['data', 'mid']),
      title: map.getString(['data', 'title']),
      cover: map.getString(['data', 'cover']),
      count: map.getInt(['data', 'media_count']),
      type: map.getInt(['data', 'type']),
    );
  }
}

class BliTicket {
  late String ticket;
  late int expireTime;
  late int createTime;
  late String imgKey;
  late String subKey;

  BliTicket({
    required this.ticket,
    required this.expireTime,
    required this.createTime,
    required this.imgKey,
    required this.subKey,
  });

  Map<String, dynamic> toMap() {
    return {
      "ticket": ticket,
      "expireTime": expireTime,
      "createTime": createTime,
      "imgKey": imgKey,
      "subKey": subKey,
    };
  }

  static BliTicket fromMap(Map<String, dynamic> map) {
    return BliTicket(
      ticket: map['ticket'],
      expireTime: map['expireTime'],
      createTime: map['createTime'],
      imgKey: map['imgKey'],
      subKey: map['subKey'],
    );
  }

  static BliTicket fromResponse(Response response) {
    var map = FormatMap(response.data);
    return BliTicket(
      ticket: map.getString(['data', 'ticket']),
      expireTime: map.getInt(['data', 'ttl']),
      createTime: map.getInt(['data', 'created_at']),
      imgKey: map.getString(['data', 'nav', 'img']),
      subKey: map.getString(['data', 'nav', 'sub']),
    );
  }
}

class BliUser {
  late String avatar;
  late int userId;
  late String userName;
  late String imgKey;
  late String subKey;

  BliUser({
    required this.avatar,
    required this.userId,
    required this.userName,
    required this.imgKey,
    required this.subKey,
  });

  BliUser.empty() {
    avatar = '';
    userId = -1;
    userName = '';
    imgKey = '';
    subKey = '';
  }

  Map<String, dynamic> toMap() {
    return {
      "avatar": avatar,
      "userId": userId,
      "userName": userName,
      "imgKey": imgKey,
      "subKey": subKey,
    };
  }

  static BliUser fromResponse(Response response) {
    var map = FormatMap(response.data);
    return BliUser(
      avatar: map.getString(['data', 'face']),
      userId: map.getInt(['data', 'mid']),
      userName: map.getString(['data', 'uname']),
      imgKey: map.getString(['data', 'wbi_img', 'img_url']),
      subKey: map.getString(['data', 'wbi_img', 'sub_url']),
    );
  }
}
