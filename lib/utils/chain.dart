import 'dart:async';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:hive/hive.dart';
import 'package:pms/utils/export.dart';

class DioChainCache<T> {
  static final Map<String, Map<String, DioChainCache>> _memory = {};

  late double expire;
  late Future<Response<T>> request;

  DioChainCache({
    required this.expire,
    required this.request,
  });

  static Map fromResponse(Response<dynamic> response) {
    return {
      'headers': response.headers.map,
      'statusCode': response.statusCode,
      'statusMessage': response.statusMessage,
      'data': response.data,
    };
  }

  static Response<T> fromMap<T>(Map json) {
    var header = json['headers'] as Map;
    Map<String, List<String>> headerMap = {};

    header.forEach((key, value) {
      if (value is List<String>) {
        headerMap[key] = value;
      }
      if (value is String) {
        headerMap[key] = [value];
      }
    });

    return Response<T>(
      headers: Headers.fromMap(headerMap),
      data: json['data'],
      statusCode: json['statusCode'],
      statusMessage: json['statusMessage'],
      requestOptions: RequestOptions(),
    );
  }

  static deleteLocalCache(String tag, [String? key]) async {
    final store = await Hive.openBox<Map>(Uri.encodeComponent(tag));
    if (key != null) {
      await store.delete(key);
    } else {
      await store.deleteFromDisk();
    }
    await store.close();
  }

  static setLocalCache<T>(
      {required String tag,
      required String key,
      required Response<T> response,
      required double time}) async {
    final store = await Hive.openBox<Map>(Uri.encodeComponent(tag));
    if (time > 0 && time != double.infinity) {
      var now = DateTime.now();
      now = now.add(Duration(milliseconds: time.toInt()));
      time = now.millisecondsSinceEpoch.ceilToDouble();
      Tool.log(['设置本地缓存', time, now.toString()]);
    }
    await store.put(key, {
      "expire": time == double.infinity ? null : time,
      "response": fromResponse(response)
    });
    await store.close();
  }

  static Future<DioChainCache<T>?> getLocalCache<T>(
      String tag, String key) async {
    final store = await Hive.openBox<Map>(Uri.encodeComponent(tag));

    var cache = store.get(key);

    if (cache == null) {
      return null;
    }

    var expire = cache['expire'] ?? double.infinity;

    if (expire < DateTime.now().millisecondsSinceEpoch) {
      await store.delete(key);
      return null;
    }

    var response = fromMap<T>(cache['response']);

    await store.close();

    return DioChainCache<T>(expire: expire, request: Future.value(response));
  }

  static deleteMemoryCache(String tag, [String? key]) {
    if (key != null && _memory[tag] != null) {
      _memory[tag]!.remove(key);
    } else {
      _memory.remove(tag);
    }
  }

  static setMemoryCache<T>({
    required String tag,
    required String key,
    required Future<Response<T>> request,
    required double time,
  }) {
    if (time > 0 && time != double.infinity) {
      var now = DateTime.now();
      now = now.add(Duration(milliseconds: time.toInt()));
      time = now.millisecondsSinceEpoch.ceilToDouble();
    }
    _memory[tag] = _memory[tag] ?? {};
    _memory[tag]![key] = DioChainCache(
      request: request,
      expire: time,
    );
  }

  DioChainCache<V>? cast<V>() {
    return DioChainCache<V>(
      expire: expire,
      request: request.then((response) {
        if (response is Response<V>) {
          return response as Response<V>;
        }
        return Response<V>(
          requestOptions: RequestOptions(),
          data: response.data as V,
          headers: response.headers,
          statusCode: response.statusCode,
          statusMessage: response.statusMessage,
        );
      }),
    );
  }

  static DioChainCache<T>? getMemoryCache<T>(String tag, String key) {
    var store = _memory[tag];
    if (store == null) {
      return null;
    }
    var cache = store[key];
    if (cache != null && cache.expire < DateTime.now().millisecondsSinceEpoch) {
      DioChainCache._memory.remove(key);
      cache = null;
    }
    return cache?.cast<T>();
  }
}

class DioChainResponse<T> implements Future<Response<T>> {
  late Future<Response<T>> _promise;
  late CancelToken _cancelToken;
  late BaseOptions options;
  late String url;

  Map<String, Object?> _config = {
    "data": null,
    "cacheType": null,
    "cacheTime": 0.0,
    "mergeSame": false,
    "forceCache": false,
    "extra": {}.cast<String, dynamic>(),
  };

  List<void Function(int, int)> _onSendProgressvoids = [];
  List<void Function(int, int)> _onReceiveProgressvoids = [];

  Map<String, dynamic> get extra {
    return _config['extra'] as Map<String, dynamic>;
  }

  Object? get body {
    return _config['data'];
  }

  set body(Object? data) {
    _config['data'] = data;
  }

  DioChainResponse({
    required this.url,
    required this.options,
    Future<Future<Response> Function(Response response)?> Function(
            DioChainResponse chain)?
        interceptor,
  }) {
    _cancelToken = CancelToken();

    _promise = Future<Response<T>>(() async {
      try {
        String key = '';
        String tag = url.startsWith(RegExp(r'http://|https://'))
            ? url
            : '${options.baseUrl}$url';

        var cacheType = _config['cacheType'] as String?;
        var cacheTime = _config['cacheTime'] as double;
        var mergeSame = _config['mergeSame'] as bool;
        var forceCache = _config['forceCache'] as bool;

        if (cacheType != null || mergeSame) {
          key = _generateFeature();
          DioChainCache<T>? cache;

          if (forceCache) {
            DioChainCache.deleteMemoryCache(tag, key);
            DioChainCache.deleteLocalCache(tag, key);
            cacheType = null;
          }

          if (cacheType == 'memory' || mergeSame) {
            cache = DioChainCache.getMemoryCache<T>(tag, key);
            logger.i(['读取内存缓存', key, cache]);
          }

          if (cacheType == 'local') {
            cache = await DioChainCache.getLocalCache<T>(tag, key);
            logger.i(['读取本地缓存', key, cache]);
          }

          if (cache != null) {
            return cache.request;
          }
        }

        options.baseUrl =
            url.startsWith(RegExp(r'http://|https://')) ? '' : options.baseUrl;
        var dio = Dio(options);

        Future<Response> Function(Response response)? handleResponse;

        if (interceptor != null) {
          handleResponse = await interceptor(this);
        }

        Object? dataTemp = body;

        var data =
            dataTemp is Map ? dataTemp.cast<String, dynamic>() : dataTemp;

        var request = dio.request<T>(
          url,
          data: data,
          cancelToken: _cancelToken,
          onReceiveProgress: (count, total) {
            for (var callback in _onReceiveProgressvoids) {
              callback(count, total);
            }
          },
          onSendProgress: (count, total) {
            for (var callback in _onSendProgressvoids) {
              callback(count, total);
            }
          },
        );

        if (mergeSame && key.isNotEmpty) {
          DioChainCache.setMemoryCache(
            tag: tag,
            key: key,
            request: request,
            time: 100,
          );
          request.whenComplete(() {
            DioChainCache.deleteMemoryCache(tag, key);
          });
        }

        logger.i([
          '请求数据',
          key,
          options.method,
          url,
          options.contentType,
          options.headers,
          data is List<int> ? data.toString() : data,
          options.queryParameters
        ]);
        var response = await request;

        if (cacheType == 'memory' && key.isNotEmpty && cacheTime > 0) {
          DioChainCache.setMemoryCache<T>(
            tag: tag,
            key: key,
            request: request,
            time: cacheTime,
          );
        }

        if (cacheType == 'local' && key.isNotEmpty && cacheTime > 0) {
          DioChainCache.setLocalCache(
            key: key,
            response: response,
            time: cacheTime,
            tag: tag,
          );
        }

        logger.i(['响应结果', response.headers, response.data]);

        if (handleResponse != null) {
          var result = await handleResponse(response);
          return result as Response<T>;
        }

        return response;
      } catch (e) {
        if (e is DioException) {
          Tool.log([
            '请求异常',
            url,
            options.method,
            e,
            e.response?.statusCode,
            e.response?.statusMessage,
            e.response?.data
          ]);
        } else {
          Tool.log(['请求异常', url, options.method, e]);
        }
        return Future.error(e);
      }
    });
  }

  DioChainResponse.packing({
    required this.url,
    required this.options,
    required Future<Response<T>> promise,
    required CancelToken cancelToken,
    required Map<String, Object?> config,
    required List<void Function(int, int)> onReceiveProgressvoids,
    required List<void Function(int, int)> onSendProgressvoids,
  }) {
    this._promise = promise;
    this._cancelToken = cancelToken;
    this._config = config;
    this._onReceiveProgressvoids = onReceiveProgressvoids;
    this._onSendProgressvoids = onSendProgressvoids;
  }

  String _generateFeature() {
    Map map = {
      "method": options.method,
      "queryParameters": options.queryParameters,
    };
    if (body is Map) {
      map['data'] = body;
    }
    var json = jsonEncode(map);
    var content = utf8.encode(json);
    var md5Digest = md5.convert(content);
    return md5Digest.toString();
  }

  DioChainResponse<T> onReceiveProgress(
      void Function(int count, int total) callback) {
    _onReceiveProgressvoids.add(callback);
    return this;
  }

  DioChainResponse<T> onSendProgress(
      void Function(int count, int total) callback) {
    _onSendProgressvoids.add(callback);
    return this;
  }

  DioChainResponse<T> setExtra(Map<String, dynamic> extra, [bool mix = true]) {
    if (mix) {
      (_config['extra'] as Map<String, dynamic>).addAll(extra);
    } else {
      _config['extra'] = extra;
    }
    return this;
  }

  /// 启用本地缓存 不调用该方法的相同请求不会读取原有的缓存数据，
  /// time 时间为毫秒,表示接口从完成请求开始 缓存多久时间，
  /// time 为double.infinity时 为永久缓存，
  /// 与 enableMergeSame 不同 只有任务执行返回结果时才缓存
  /// forceCache 当前请求的数据覆盖之前缓存的数据
  DioChainResponse<T> setLocalCache(double time, [bool forceCache = false]) {
    _config['cacheTime'] = time;
    _config['cacheType'] = 'local';
    _config['forceCache'] = forceCache;
    return this;
  }

  /// 启用内存缓存 不调用该方法的相同请求不会读取原有的缓存数据，
  /// time 时间为毫秒,表示接口从完成请求开始 缓存多久时间，
  /// time 为double.infinity时 缓存到程序结束为止，
  /// 与 enableMergeSame 不同 只有任务执行返回结果时才缓存
  /// forceCache 当前请求的数据覆盖之前缓存的数据
  DioChainResponse<T> setMemoryCache(double time, [bool forceCache = false]) {
    _config['cacheTime'] = time;
    _config['cacheType'] = 'memory';
    _config['forceCache'] = forceCache;
    return this;
  }

  /// 表示当前请求不启用缓存机制
  DioChainResponse<T> disableCache() {
    _config['cacheTime'] = null;
    _config['cacheType'] = null;
    return this;
  }

  /// 如果两个相同的请求 同一时间执行时 将会进行合并
  /// 与setMemoryCache不同 这个将在请求前缓存 在请求完成后删除
  DioChainResponse<T> enableMergeSame() {
    _config['mergeSame'] = true;
    return this;
  }

  DioChainResponse<T> setCookie(String cookie) {
    return setHeaders({'Cookie': cookie});
  }

  DioChainResponse<T> disableMergeSame() {
    _config['mergeSame'] = false;
    return this;
  }

  DioChainResponse<T> headerFormUrlencoded() {
    return setHeaders({'content-type': 'application/x-www-form-urlencoded'});
  }

  DioChainResponse<T> headerFormData() {
    return setHeaders({'content-type': 'multipart/form-data'});
  }

  DioChainResponse<T> headerJson() {
    return setHeaders({'content-type': 'application/json'});
  }

  DioChainResponse<T> headerStream() {
    Tool.log('headerStream');
    return setHeaders({'content-type': 'application/octet-stream'});
  }

  bool get isFormUrlencoded {
    return options.headers['content-type'] ==
        'application/x-www-form-urlencoded';
  }

  bool get isFormData {
    return options.headers['content-type'] == 'multipart/form-data';
  }

  bool get isJson {
    return options.headers['content-type'] == 'application/json';
  }

  DioChainResponse<T> setRange(int start, [int? end]) {
    return setHeaders({'Range': 'bytes=$start-${end ?? ''}'});
  }

  DioChainResponse<T> setHeaders(Map<String, dynamic> headers,
      [bool mix = true]) {
    if (headers['content-type'] != null) {
      options.contentType = headers['content-type'];
    }
    if (headers['Content-Type'] != null) {
      options.contentType = headers['Content-Type'];
    }
    if (mix) {
      options.headers.addAll(headers);
    } else {
      options.headers = headers;
    }
    return this;
  }

  DioChainResponse<T> setReferer(String? value) {
    return setHeaders({"Referer": value});
  }

  DioChainResponse<T> setUserAgent(String? value) {
    var agent = value ??
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36 Edg/131.0.0.0';
    return setHeaders({"User-Agent": agent});
  }

  DioChainResponse<T> setAuthorization(String token, [String type = 'Bearer']) {
    return setHeaders({
      "Authorization": "$type $token",
    });
  }

  /// 获取响应结果，如果结果为空则抛异常
  Future<T> getData() {
    return this._promise.then((response) {
      var data = response.data;
      if (data == null) {
        return Future.error(Exception('data数据不存在'));
      }
      return data;
    });
  }

  /// 获取响应结果
  Future<T?> getSource() {
    return this._promise.then((response) => response.data);
  }

  DioChainResponse<U> format<U>(U? Function(Response<T> response) format) {
    return DioChainResponse<U>.packing(
      cancelToken: _cancelToken,
      url: url,
      options: options,
      config: _config,
      onReceiveProgressvoids: _onReceiveProgressvoids,
      onSendProgressvoids: _onSendProgressvoids,
      promise: this._promise.then((response) {
        return Response<U>(
          data: format(response),
          requestOptions: response.requestOptions,
          headers: response.headers,
          isRedirect: response.isRedirect,
          statusCode: response.statusCode,
          statusMessage: response.statusMessage,
          redirects: response.redirects,
          extra: response.extra,
        );
      }),
    );
  }

  DioChainResponse<T> cancel(Object? reason) {
    _cancelToken.cancel(reason);
    return this;
  }

  bool get isCanceled {
    return _cancelToken.isCancelled;
  }

  DioChainResponse<T> send(Object data, [bool mix = true]) {
    if (body == null || mix == false) {
      body = data;
      return this;
    }
    var source = body;
    if (source is Map && data is Map) {
      source.addAll(data);
    } else if (source is List && data is List) {
      source.addAll(data);
    } else {
      body = data;
    }
    return this;
  }

  DioChainResponse<T> query(Map<String, dynamic> params, [bool mix = true]) {
    if (mix) {
      options.queryParameters.addAll(params);
    } else {
      options.queryParameters = params;
    }
    return this;
  }

  DioChainResponse<T> setOptions({
    DioChainMethod? method,
    String? baseUrl,
    Map<String, dynamic>? headers,
    ResponseType? responseType,
    String? contentType,
    ValidateStatus? validateStatus,
  }) {
    options.method = method != null ? method.name : options.method;
    options.baseUrl = baseUrl ?? options.baseUrl;
    options.headers = headers ?? options.headers;
    options.responseType = responseType ?? options.responseType;
    options.contentType = contentType ?? options.contentType;
    options.validateStatus = validateStatus ?? options.validateStatus;
    return this;
  }

  @override
  Stream<Response<T>> asStream() {
    return _promise.asStream();
  }

  @override
  Future<Response<T>> catchError(Function onError,
      {bool Function(Object error)? test}) {
    return _promise.catchError(onError, test: test);
  }

  @override
  Future<R> then<R>(FutureOr<R> Function(Response<T> value) onValue,
      {Function? onError}) {
    return _promise.then(onValue, onError: onError);
  }

  @override
  Future<Response<T>> timeout(Duration timeLimit,
      {FutureOr<Response<T>> Function()? onTimeout}) {
    return _promise.timeout(timeLimit, onTimeout: onTimeout);
  }

  @override
  Future<Response<T>> whenComplete(FutureOr<void> Function() action) {
    return _promise.whenComplete(action);
  }
}

enum DioChainMethod { post, get, put, head }

class DioChain {
  late BaseOptions _options = BaseOptions();
  Future<Future<Response> Function(Response response)?> Function(
      DioChainResponse chain)? _interceptor;

  DioChain({
    String? baseUrl,
    Map<String, dynamic> headers = const {},
    ValidateStatus? validateStatus,
    ResponseType? responseType,
    Future<Future<Response> Function(Response response)?> Function(
            DioChainResponse chain)?
        interceptor,
  }) {
    _interceptor = interceptor;
    _options = _options.copyWith(
      baseUrl: baseUrl,
      headers: headers,
      validateStatus: validateStatus,
      responseType: responseType ?? ResponseType.json,
    );
  }

  DioChain headerFormUrlencoded() {
    return setHeaders({'content-type': 'application/x-www-form-urlencoded'});
  }

  DioChain headerFormData() {
    return setHeaders({'content-type': 'multipart/form-data'});
  }

  DioChain headerJson() {
    return setHeaders({'content-type': 'application/json'});
  }

  DioChain setHeaders(Map<String, dynamic> headers, [mix = true]) {
    if (mix) {
      _options.headers.addAll(headers);
    } else {
      _options.headers = headers;
    }
    return this;
  }

  DioChain setReferer(String value) {
    return setHeaders({"Referer": value});
  }

  DioChain setUserAgent([String? value]) {
    var agent = value ??
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36 Edg/131.0.0.0';
    return setHeaders({"User-Agent": agent});
  }

  DioChainResponse<T> request<T>({
    required String url,
    required DioChainMethod method,
    Map<String, String>? headers,
    Map<String, dynamic>? queryParameters,
    Object? data,
    ResponseType? responseType = ResponseType.json,
    ValidateStatus? validateStatus,
  }) {
    var chain = DioChainResponse<T>(
      options: _options.copyWith(
        method: method.toString().split('.').last,
        queryParameters: {
          ..._options.queryParameters,
          ...?queryParameters,
        },
        headers: {
          ..._options.headers,
          ...?headers,
        },
        responseType: responseType,
        validateStatus: validateStatus,
      ),
      url: url,
      interceptor: _interceptor,
    );
    return chain;
  }

  DioChainResponse<T> get<T>(String url, [Map<String, dynamic>? params]) {
    return request<T>(
      url: url,
      method: DioChainMethod.get,
    ).query(params ?? {});
  }

  DioChainResponse<T> head<T>(String url, [Map<String, dynamic>? params]) {
    return request<T>(
      url: url,
      method: DioChainMethod.head,
    ).query(params ?? {});
  }

  DioChainResponse<ResponseBody> getStream(String url,
      [Map<String, dynamic>? params]) {
    return request<ResponseBody>(
      url: url,
      method: DioChainMethod.get,
      responseType: ResponseType.stream,
    ).query(params ?? {});
  }

  DioChainResponse<ResponseBody> postStream(
    String url, {
    Map<String, dynamic>? params,
    Object? data,
  }) {
    return request<ResponseBody>(
      url: url,
      method: DioChainMethod.post,
    ).send(data ?? {});
  }

  DioChainResponse<T> post<T>(
    String url, {
    Map<String, dynamic>? params,
    Object? data,
  }) {
    return request<T>(
      url: url,
      method: DioChainMethod.post,
    ).send(data ?? {});
  }

  DioChainResponse<T> put<T>(
    String url, {
    Map<String, dynamic>? params,
    Object? data,
  }) {
    return request<T>(
      url: url,
      method: DioChainMethod.put,
    ).send(data ?? {});
  }
}
