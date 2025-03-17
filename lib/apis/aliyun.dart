import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:pms/utils/export.dart';
import 'package:convert/convert.dart';
import 'package:secp256k1_ecdsa/secp256k1.dart';
import 'package:secp256k1cipher/secp256k1cipher.dart';

var _chain = DioChain(
  headers: {
    "User-Agent":
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) aDrive/6.3.1 Chrome/112.0.5615.165 Electron/24.1.3.7 Safari/537.36",
    "x-canary": "client=Windows,app=adrive,version=v6.4.2",
    "Referer": "https://www.aliyundrive.com/",
    "sec-fetch-dest": "empty",
    "sec-fetch-mode": "no-cors",
    "sec-fetch-site": "none",
    // "origin": "https://www.aliyundrive.com",
  },
);

class AliyunApi {
  static String deviceReferer = "https://www.aliyundrive.com/";
  static String webReferer = "https://www.alipan.com/";

  static String generateRandomDeviceId() {
    String uuidTemplate = "xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx";
    return uuidTemplate.replaceAllMapped(RegExp(r'[xy]'), (Match match) {
      String e = match.group(0)!;
      int t = (16 * Random().nextDouble()).floor();
      int replacementValue;
      if (e == "x") {
        replacementValue = t;
      } else {
        replacementValue = (3 & t) | 8;
      }
      return replacementValue.toRadixString(16);
    });
  }

  static xSignature({
    required String privateKeyHex,
    required String appId,
    required String xDeviceId,
    required String userId,
    int nonce = 0,
  }) {
    var message = '$appId:$xDeviceId:$userId:$nonce';
    final hash = sha256.convert(utf8.encode(message));

    final privateKey = PrivateKey.fromHex(privateKeyHex);

    final signature = privateKey.sign(Utilities.hexToBytes(hash.toString()));

    return '${signature.r.toRadixString(16)}${signature.s.toRadixString(16)}0${signature.recovery}';
  }

  ///  [ privateKeyHex,publicKeyHex ]
  static Future<List<String>> generatePrivateKeyHex({
    required String userId,
    required String token,
    required String xDeviceId,
    required String appId,
    int nonce = 0,
  }) async {
    var alic = generateKeyPair();
    var privateKeyHex = strinifyPrivateKey(alic.privateKey);
    var publicKeyHex = strinifyPublicKey(alic.publicKey);

    await _chain
        .post(
          "https://api.aliyundrive.com/users/v1/users/device/create_session",
        )
        .send({
          "deviceName": "pms",
          "modelName": "Windows客户端",
          "pubKey": publicKeyHex,
          "user_id": userId,
        })
        .setHeaders({
          "x-signature": xSignature(
            privateKeyHex: privateKeyHex,
            userId: userId,
            xDeviceId: xDeviceId,
            appId: appId,
            nonce: nonce,
          ),
          "x-device-id": xDeviceId,
        })
        .setAuthorization(token);

    return [privateKeyHex, publicKeyHex];
  }

  static DioChainResponse<AliToken> refreshToken({
    required String appId,
    required String refreshToken,
  }) {
    return _chain
        .post<Map>('https://auth.aliyundrive.com/v2/account/token')
        .send({
          "grant_type": "refresh_token",
          "app_id": appId,
          "refresh_token": refreshToken,
        })
        .format(AliToken.fromResponse);
  }

  static DioChainResponse<AliUser> getUserInfo(String token) {
    return _chain
        .post<Map>('https://user.aliyundrive.com/v2/user/get')
        .setHeaders({"Authorization": 'Bearer $token'})
        .format(AliUser.fromResponse);
  }

  static DioChainResponse<AliFiles> getFiles({
    required String driveId,
    required String xDeviceId,
    required String token,
    required String xSignature,
    bool all = false,
    int limit = 10,
    String parentFileId = 'root',
    String? marker,
  }) {
    const url =
        "https://api.aliyundrive.com/adrive/v3/file/list?jsonmask=next_marker%2Citems(name%2Cfile_id%2Cdrive_id%2Ctype%2Csize%2Ccreated_at%2Cupdated_at%2Ccategory%2Cfile_extension%2Cparent_file_id%2Cmime_type%2Cstarred%2Cthumbnail%2Curl%2Cstreams_info%2Ccontent_hash%2Cuser_tags%2Cuser_meta%2Ctrashed%2Cvideo_media_metadata%2Cvideo_preview_metadata%2Csync_meta%2Csync_device_flag%2Csync_flag%2Cpunish_flag%2Cfrom_share_id)";
    return _chain
        .post<Map>(url)
        .format(AliFiles.fromResponse)
        .send({
          "parent_file_id": parentFileId,
          "limit": limit,
          "all": all,
          "url_expire_sec": 14400,
          "image_thumbnail_process": "image/resize,w_400/format,jpeg",
          "image_url_process": "image/resize,w_1920/format,jpegjpeg",
          "video_thumbnail_process":
              "video/snapshot,t_120000,f_jpg,m_lfit,w_400,ar_auto,m_fast",
          "fields": "*",
          "order_by": "updated_at",
          "order_direction": "DESC",
          "drive_id": driveId,
          "marker": marker,
        })
        .setHeaders({'x-signature': xSignature, 'x-device-id': xDeviceId})
        .setAuthorization(token);
  }

  static DioChainResponse<AliFile> createDir({
    required String driveId,
    required String xDeviceId,
    required String token,
    required String xSignature,
    required String name,
    String parentFileId = 'root',
  }) {
    var url = 'https://api.aliyundrive.com/adrive/v2/file/createWithFolders';
    return _chain
        .post<Map>(url)
        .format(AliFile.fromResponse)
        .send({
          "check_name_mode": "refuse",
          "type": "folder",
          "parent_file_id": parentFileId,
          "drive_id": driveId,
          "name": name,
        })
        .setHeaders({'x-signature': xSignature, 'x-device-id': xDeviceId})
        .setAuthorization(token);
  }

  static DioChainResponse<String> getDonwloadUrl({
    required String fileId,
    required String driveId,
    required String xDeviceId,
    required String token,
    required String xSignature,
  }) {
    var url = 'https://api.aliyundrive.com/v2/file/get_download_url';
    return _chain
        .post<Map>(url)
        .format((response) {
          var map = FormatMap(response.data);
          return map.getString(['url']);
        })
        .send({"file_id": fileId, "drive_id": driveId, "expire_sec": 14400})
        .setHeaders({'x-signature': xSignature, 'x-device-id': xDeviceId})
        .setAuthorization(token)
        .setLocalCache(30 * 60 * 1000);
  }

  static DioChainResponse<ResponseBody> download({
    required String url,
    required String referer,
  }) {
    return _chain
        .getStream(url)
        .setHeaders({"Connection": "keep-alive"})
        .setReferer(referer);
  }

  static DioChainResponse<Map> reportTask({
    required int sliceNum,
    required String driveId,
    required String xDeviceId,
    required String token,
    required String xSignature,
  }) {
    var url = "https://api.aliyundrive.com/adrive/v2/file/reportDownloadTask";
    return _chain
        .post<Map>(url)
        .send({"slice_num": sliceNum, "drive_id": driveId})
        .setHeaders({'x-signature': xSignature, 'x-device-id': xDeviceId})
        .setAuthorization(token)
        .enableMergeSame()
        .setMemoryCache(1000);
  }

  static DioChainResponse<List<AliMediaInfo>> getVideoPreviewList({
    required String fileId,
    required String driveId,
    required String xDeviceId,
    required String token,
    required String xSignature,
  }) {
    var url = "https://api.aliyundrive.com/v2/file/get_video_preview_play_info";
    return _chain
        .post<Map>(url)
        .send({
          "category": "quick_video",
          "mode": "high_res",
          "get_subtitle_info": true,
          "url_expire_sec": 14400,
          "template_id": "",
          "file_id": fileId,
          "drive_id": driveId,
        })
        .setHeaders({'x-signature': xSignature, 'x-device-id': xDeviceId})
        .setAuthorization(token)
        .setLocalCache(30 * 60 * 1000)
        .format(AliMediaInfo.fromVideo);
  }

  static DioChainResponse<List<AliMediaInfo>> getAudioPreviewList({
    required String fileId,
    required String driveId,
    required String xDeviceId,
    required String token,
    required String xSignature,
  }) {
    var url =
        "https://api.aliyundrive.com/adrive/v2/databox/get_audio_play_info";
    return _chain
        .post<Map>(url)
        .send({"file_id": fileId, "drive_id": driveId})
        .setHeaders({'x-signature': xSignature, 'x-device-id': xDeviceId})
        .setAuthorization(token)
        .setLocalCache(15 * 60 * 1000)
        .format(AliMediaInfo.fromAudio);
  }

  /// @param categorys "audio" | "video" ,
  /// @param type "file" | "folder" ,
  static DioChainResponse<AliFiles> search({
    required String driveId,
    required String xDeviceId,
    required String token,
    required String xSignature,
    List<String>? parentFileIds,
    String? type,
    List<String>? categorys,
    List<String>? names,
    List<String>? fileIds,
    bool all = false,
    int limit = 10,
    String? marker,
  }) {
    String query = "";

    if (parentFileIds != null) {
      query =
          '(${parentFileIds.map((value) => 'parent_file_id = \'$value\'').toList().join(' or ')})';
    }

    if (fileIds != null) {
      query =
          '(${fileIds.map((value) => 'file_id = \'$value\'').toList().join(' or ')})';
    }

    if (categorys != null) {
      if (query.isNotEmpty) {
        query += ' and ';
      }
      query +=
          '(${categorys.map((value) => 'category = \'$value\'').toList().join(' or ')})';
    }

    if (names != null) {
      if (query.isNotEmpty) {
        query += ' and ';
      }
      query +=
          '(${names.map((value) => 'name = \'$value\'').toList().join(' or ')})';
    }

    if (type != null) {
      if (query.isNotEmpty) {
        query += ' and ';
      }
      query += '(type = \'$type\')';
    }

    var url = 'https://api.aliyundrive.com/adrive/v3/file/search';
    return _chain
        .post(url)
        .send({
          "limit": limit,
          "query": query,
          "image_thumbnail_process": "image/resize,w_256/format,avif",
          "image_url_process": "image/resize,w_1920/format,avif",
          "video_thumbnail_process":
              "video/snapshot,t_120000,f_jpg,m_lfit,w_256,ar_auto,m_fast",
          "order_by": "updated_at DESC",
          "fields": "*",
          "drive_id": driveId,
          "marker": marker,
          "all": all,
        })
        .setHeaders({'x-signature': xSignature, 'x-device-id': xDeviceId})
        .setAuthorization(token)
        .format(AliFiles.fromResponse);
  }

  static DioChainResponse<AliFolderSizeInfo> getFolderSizeInfo({
    required String fileId,
    required String driveId,
    required String xDeviceId,
    required String token,
    required String xSignature,
  }) {
    var url = 'https://api.aliyundrive.com/adrive/v1/file/get_folder_size_info';
    return _chain
        .post(url)
        .send({"file_id": fileId, "drive_id": driveId})
        .setHeaders({'x-signature': xSignature, 'x-device-id': xDeviceId})
        .setAuthorization(token)
        .format(AliFolderSizeInfo.fromResponse);
  }

  static DioChainResponse<Map> logout({
    required String driveId,
    required String userId,
    required String xDeviceId,
    required String token,
    required String xSignature,
  }) {
    var url = "https://api.aliyundrive.com/users/v1/users/device_logout";
    return _chain
        .post<Map>(url)
        .send({"user_id": userId, "drive_id": driveId})
        .setHeaders({'x-signature': xSignature, 'x-device-id': xDeviceId})
        .setAuthorization(token);
  }

  static DioChainResponse deleteFile({
    required List<String> fileIds,
    required String driveId,
    required String xDeviceId,
    required String token,
    required String xSignature,
  }) {
    var url = "https://api.aliyundrive.com/adrive/v4/batch";
    return _chain
        .post<Map>(url)
        .send({
          "resource": 'file',
          "requests":
              fileIds.map((id) {
                return {
                  "body": {
                    "drive_id": driveId,
                    "file_id": id,
                    "permanently": true,
                  },
                  "headers": {"Content-Type": "application/json"},
                  "id": id,
                  "method": "POST",
                  "url": "/file/delete",
                };
              }).toList(),
        })
        .setHeaders({'x-signature': xSignature, 'x-device-id': xDeviceId})
        .setAuthorization(token);
  }

  static Future<AliUploadInfo> getUploadPaths({
    required String filePath,
    required String driveId,
    required String xDeviceId,
    required String token,
    required String xSignature,
    required String parentFileId,
  }) async {
    var url = "https://api.aliyundrive.com/adrive/v2/file/createWithFolders";

    var uploader = AliUploadInfo(filePath);

    var params = await uploader.generateParams(token);

    try {
      /// 上传链接45分钟过期
      var response =
          await _chain
              .post<Map>(url)
              .send({
                ...params,
                'parent_file_id': parentFileId,
                'drive_id': driveId,
              })
              .setLocalCache(2700000)
              .setHeaders({'x-signature': xSignature, 'x-device-id': xDeviceId})
              .setAuthorization(token)
              .getData();

      if (response['rapid_upload'] == true) {
        uploader.isFinish = true;
        return uploader;
      }

      List uploadUrls = response['part_info_list'];

      uploader.partUrls =
          uploadUrls.map((item) => item['upload_url']).cast<String>().toList();
      uploader.fileId = response['file_id'];
      uploader.uploadId = response['upload_id'];

      return uploader;
    } catch (e) {
      if (e is DioException && e.response?.statusCode == 409) {
        try {
          params.remove('pre_hash');
          var proofCode = await uploader.generateProofCode(token);
          params.addAll(proofCode);
          await _chain
              .post<Map>(url)
              .send({
                ...params,
                'parent_file_id': parentFileId,
                'drive_id': driveId,
              })
              .setHeaders({'x-signature': xSignature, 'x-device-id': xDeviceId})
              .setAuthorization(token)
              .getData();
          uploader.isFinish = true;
          return uploader;
        } catch (error) {
          return Future.error(e);
        }
      }

      if (e is DioException) {
        Tool.log(e.response?.data);
      }

      return Future.error(e);
    }
  }

  static DioChainResponse uploadPart({
    required String partUrl,
    required Stream<List<int>> chunk,
  }) {
    return _chain
        .put(partUrl, data: chunk)
        .setHeaders({"connection": "keep-alive", "content-type": ""})
        .setOptions(validateStatus: (status) => status == 200 || status == 409);
  }

  static DioChainResponse mergeUploadPart({
    required String fileId,
    required String uploadId,
    required String driveId,
    required String xDeviceId,
    required String token,
    required String xSignature,
  }) {
    var url = "https://api.aliyundrive.com/v2/file/complete";
    return _chain
        .post(url)
        .send({"file_id": fileId, "upload_id": uploadId, "drive_id": driveId})
        .setHeaders({'x-signature': xSignature, 'x-device-id': xDeviceId})
        .setAuthorization(token);
  }

  static DioChainResponse share({
    required List<String> fileIds,
    required String driveId,
    required String xDeviceId,
    required String token,
    required String xSignature,
  }) {
    var url = 'https://api.aliyundrive.com/adrive/v2/share_link/create';
    return _chain
        .post(url)
        .send({
          'file_id_list': fileIds,
          'drive_id': driveId,
          'expiration': "2024-12-31T08:53:30.907Z",
        })
        .setHeaders({'x-signature': xSignature, 'x-device-id': xDeviceId})
        .setAuthorization(token);
  }
}

class AliUploadInfo {
  late String name;
  late int fileSize;
  late File file;
  late List<int> parts;
  late List<String> partUrls;
  late bool isFinish = false;
  final int chunkSize = 10485824;
  late String fileId = '';
  late String uploadId = '';

  AliUploadInfo(String filepath) {
    file = File(filepath);
    fileSize = file.lengthSync();
    parts = [];
    partUrls = [];

    name = filepath.split('/').last;

    int partSize = chunkSize;

    while (fileSize > partSize * 8000) {
      partSize = partSize + chunkSize;
    }

    while (parts.length * partSize < fileSize) {
      parts.add(partSize);
    }

    parts.last = fileSize - (parts.length - 1) * partSize;
  }

  Future<Map> generatePreHash() async {
    var randomAccessFile = await file.open();
    var bytes = Uint8List(1024);
    await randomAccessFile.setPosition(0);
    await randomAccessFile.readInto(bytes);
    await randomAccessFile.close();
    var digest = sha1.convert(bytes);
    var preHash = digest.toString().toLowerCase();
    return {'pre_hash': preHash};
  }

  Future<Map<String, String>> generateProofCode(String token) async {
    // 计算 token 的 MD5 哈希值
    var buffa = utf8.encode(token);
    var md5a = md5.convert(buffa).toString();

    // 获取文件大小
    var fileLength = await file.length();

    // 计算 start 和 end
    var start =
        (BigInt.parse(md5a.substring(0, 16), radix: 16) %
                BigInt.from(fileLength))
            .toInt();
    var end = (start + 8).clamp(0, fileLength);

    // 获取子数组并转换为 base64
    var randomAccessFile = await file.open();
    var buffb = Uint8List(end - start);
    await randomAccessFile.setPosition(start);
    await randomAccessFile.readInto(buffb);
    await randomAccessFile.close();
    var proofCode = base64Encode(buffb);

    // 计算内容哈希值
    var contentHashName = 'sha1';
    var digestSink = AccumulatorSink<Digest>();
    var sha1Sink = sha1.startChunkedConversion(digestSink);
    await for (var chunk in file.openRead()) {
      sha1Sink.add(chunk);
    }
    sha1Sink.close();
    var contentHash = digestSink.events.single.toString().toUpperCase();

    return {
      'proof_code': proofCode,
      'content_hash': contentHash,
      'content_hash_name': contentHashName,
      'proof_version': 'v1',
    };
  }

  Future<Map> generateParams(String token) async {
    Map extra = {};

    if (fileSize > 1024000) {
      extra = await generatePreHash();
    } else {
      extra = await generateProofCode(token);
    }

    return {
      'part_info_list':
          parts.asMap().entries.map((item) {
            return {'part_number': item.key + 1, 'part_size': item.value};
          }).toList(),
      'name': name,
      'type': 'file',
      'check_name_mode': 'auto_rename',
      'size': fileSize,
      'create_scene': 'file_upload',
      'device_name': '',
      ...extra,
    };
  }

  Stream<List<int>> getPartChunk(int part) {
    var start = part * chunkSize;
    var end = min((part + 1) * chunkSize, fileSize);
    return file.openRead(start, end);
  }
}

class AliFolderSizeInfo {
  late double size;
  late int fileCount;
  late int folderCount;

  AliFolderSizeInfo({
    required this.size,
    required this.fileCount,
    required this.folderCount,
  });

  static AliFolderSizeInfo fromResponse(Response response) {
    var map = FormatMap(response.data);
    return AliFolderSizeInfo(
      size: map.getInt(['size']).toDouble(),
      fileCount: map.getInt(['file_count']),
      folderCount: map.getInt(['folder_count']),
    );
  }
}

class AliMediaInfo {
  late int width;
  late int height;
  late double duration;
  late String url;
  late String type;

  AliMediaInfo({
    required this.width,
    required this.height,
    required this.duration,
    required this.url,
    required this.type,
  });

  bool get isVideo {
    return type == 'video';
  }

  bool get isAudio {
    return type == 'audio';
  }

  static List<AliMediaInfo> fromVideo(Response<Map> response) {
    var map = FormatMap(response.data);
    List<AliMediaInfo> list = [];
    var duration = map.getDouble([
      'video_preview_play_info',
      'meta',
      'duration',
    ]);
    var temps = map.getList(['video_preview_play_info', 'quick_video_list']);
    for (var item in temps) {
      if (item['url'] == '') {
        continue;
      }
      list.add(
        AliMediaInfo(
          width: item['template_width'],
          height: item['template_height'],
          url: item['url'],
          duration: duration,
          type: 'video',
        ),
      );
    }
    return list;
  }

  static List<AliMediaInfo> fromAudio(Response<Map> response) {
    var map = FormatMap(response.data);
    List<AliMediaInfo> list = [];

    var temps = map.getList(['template_list']);

    for (var item in temps) {
      if (item['url'] == '') {
        continue;
      }
      list.add(
        AliMediaInfo(
          width: 0,
          height: 0,
          url: item['url'],
          duration: 0,
          type: 'audio',
        ),
      );
    }
    return list;
  }
}

class AliFiles {
  late String nextMarker;
  late List<AliFile> items;

  AliFiles({required this.nextMarker, required this.items});

  static AliFiles fromResponse(Response response) {
    var map = FormatMap(response.data);
    var items =
        map.getList(['items']).map((item) => AliFile.fromMap(item)).toList();
    return AliFiles(nextMarker: map.getString(['next_marker']), items: items);
  }

  Map<String, dynamic> toMap() {
    return {
      "nextMarker": nextMarker,
      "items": items.map((item) => item.toMap()).toList(),
    };
  }
}

class AliFile {
  late String fileId;
  late String parentFileId;
  late String name;
  late String type;
  late String driveId;
  late String url;
  late String thumbnail;
  late int size;
  late String contentHash;
  late String mimeType;
  late String fileExtension;
  late String category;
  late String albumName;
  late String artist;

  AliFile({
    required this.fileId,
    required this.parentFileId,
    required this.name,
    required this.type,
    required this.driveId,
    this.url = '',
    this.thumbnail = '',
    this.size = 0,
    this.contentHash = '',
    this.mimeType = '',
    this.fileExtension = '',
    this.category = '',
    this.albumName = '',
    this.artist = '',
  });

  static AliFile fromMap(Map? json, [String? referer]) {
    var map = FormatMap(json);
    return AliFile(
      fileId: map.getString(['file_id']),
      parentFileId: map.getString(['parent_file_id']),
      name: map.getString([
        'video_preview_metadata',
        'audio_music_meta',
        'title',
      ], map.getString(['name'], map.getString(['file_name']))),
      type: map.getString(['type']),
      driveId: map.getString(['drive_id']),
      url: map.getString(['url']),
      size: map.getInt(['size']),
      contentHash: map.getString(['content_hash']),
      mimeType: map.getString(['mime_type']),
      fileExtension: map.getString(['file_extension']),
      category: map.getString(['category']),
      thumbnail: map.getString(
        ['thumbnail'],
        map.getString([
          'video_preview_metadata',
          'audio_music_meta',
          'cover_url',
        ]),
      ),
      albumName: map.getString([
        'video_preview_metadata',
        'audio_music_meta',
        'album',
      ]),
      artist: map.getString([
        'video_preview_metadata',
        'audio_music_meta',
        'artist',
      ]),
    );
  }

  static AliFile fromResponse(Response response) {
    var model = fromMap(response.data);
    return model;
  }

  Map<String, dynamic> toMap() {
    return {
      "fileId": fileId,
      "parentFileId": parentFileId,
      "name": name,
      "type": type,
      "driveId": driveId,
      "url": url,
      "size": size,
      "category": category,
      "contentHash": contentHash,
      "mimeType": mimeType,
      "fileExtension": fileExtension,
      "thumbnail": thumbnail,
      "artist": artist,
      "albumName": albumName,
    };
  }

  bool get isFile {
    return type == 'file';
  }

  bool get isFolder {
    return type == 'folder';
  }
}

class AliUser {
  late String avatar;
  late String phone;
  late String backupDriveId;
  late String resourceDriveId;
  late String userId;
  late String userName;
  late String defaultDriveId;
  late String displayName;
  late String nickName;

  AliUser({
    required this.avatar,
    required this.phone,
    required this.backupDriveId,
    required this.defaultDriveId,
    required this.displayName,
    required this.resourceDriveId,
    required this.userId,
    required this.userName,
    required this.nickName,
  });

  AliUser.empty() {
    avatar = '';
    phone = '';
    backupDriveId = '';
    defaultDriveId = '';
    displayName = '';
    resourceDriveId = '';
    userId = '';
    userName = '';
    nickName = '';
  }

  Map<String, dynamic> toMap() {
    return {
      "avatar": avatar,
      "phone": phone,
      "backupDriveId": backupDriveId,
      "defaultDriveId": defaultDriveId,
      "displayName": displayName,
      "resourceDriveId": resourceDriveId,
      "userId": userId,
      "userName": userName,
    };
  }

  static AliUser fromResponse(Response response) {
    var map = FormatMap(response.data);
    return AliUser(
      avatar: map.getString(['avatar']),
      userId: map.getString(['user_id']),
      userName: map.getString(['user_name']),
      defaultDriveId: map.getString(['default_drive_id']),
      phone: map.getString(['phone']),
      backupDriveId: map.getString(['backup_drive_id']),
      displayName: map.getString(['display_name']),
      resourceDriveId: map.getString(['resource_drive_id']),
      nickName: map.getString(['nick_name']),
    );
  }
}

class AliToken {
  late String deviceId;
  late String userName;
  late String expireTime;
  late String avatar;
  late String accessToken;
  late String refreshToken;
  late String userId;
  late String nickName;

  AliToken({
    required this.accessToken,
    required this.deviceId,
    required this.avatar,
    required this.expireTime,
    required this.nickName,
    required this.refreshToken,
    required this.userId,
    required this.userName,
  });

  AliToken.empty() {
    accessToken = '';
    deviceId = '';
    avatar = '';
    expireTime = '';
    nickName = '';
    refreshToken = '';
    userId = '';
    userName = '';
  }

  bool get isExpire {
    return DateTime.parse(expireTime).millisecondsSinceEpoch <
        DateTime.now().millisecondsSinceEpoch;
  }

  Map<String, dynamic> toMap() {
    return {
      "accessToken": accessToken,
      "deviceId": deviceId,
      "avatar": avatar,
      "expireTime": expireTime,
      "nickName": nickName,
      "refreshToken": refreshToken,
      "userId": userId,
      "userName": userName,
    };
  }

  static AliToken fromMap(Map json) {
    var map = FormatMap(json);
    return AliToken(
      accessToken: map.getString(['access_token']),
      deviceId: map.getString(['device_id']),
      avatar: map.getString(['avatar']),
      expireTime: map.getString(['expire_time']),
      nickName: map.getString(['nick_name']),
      refreshToken: map.getString(['refresh_token']),
      userId: map.getString(['user_id']),
      userName: map.getString(['user_name']),
    );
  }

  static AliToken fromResponse(Response response) {
    return fromMap(response.data);
  }
}
