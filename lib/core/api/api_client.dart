// 执行模式 9：单例 Dio + 401 拦截器（自动 refresh + 重放）。
//
// 设计要点（Simplicity First）：
//  - 全局只暴露一个 Dio 实例；所有 Repository 通过 ApiClient 注入。
//  - EnvConfig.baseUrl 变更后必须重建 ApiClient（在 AuthController 切地址时处理）。
//  - 401 串行化：用 _refreshing 锁防止并发 N 次 refresh。
//  - refresh 成功 → 写入新 token + 重放原请求一次；refresh 失败 → SessionExpiredException。
//  - /auth/refresh 与 /auth/register / /auth/login 三个端点不挂 Authorization，跳过。

import 'dart:async';

import 'package:dio/dio.dart';

import '../env/env_config.dart';
import '../storage/token_storage.dart';
import 'api_envelope.dart';
import 'api_exception.dart';

typedef OnSessionExpired = Future<void> Function();
typedef ApiDataParser<T> = T Function(dynamic raw);

class ApiClient {
  ApiClient({required this.tokenStorage, required EnvConfig env})
    : env = env,
      _dio = Dio(
        BaseOptions(
          baseUrl: env.apiPrefix,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 30),
          contentType: 'application/json; charset=utf-8',
          responseType: ResponseType.json,
        ),
      ) {
    _dio.interceptors.add(_AuthInterceptor(this));
    env.addListener(_updateBaseUrl);
  }

  ApiClient.forBaseUrl({required this.tokenStorage, required String baseUrl})
    : env = null,
      _dio = Dio(
        BaseOptions(
          baseUrl: _apiPrefix(baseUrl),
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 30),
          contentType: 'application/json; charset=utf-8',
          responseType: ResponseType.json,
        ),
      ) {
    _dio.interceptors.add(_AuthInterceptor(this));
  }

  final TokenStorage tokenStorage;
  final EnvConfig? env;
  final Dio _dio;
  Completer<bool>? _refreshing;

  OnSessionExpired? _onSessionExpired;
  String? _cachedAccessToken;

  Dio get dio => _dio;
  String get baseUrl => env?.baseUrl ?? _dio.options.baseUrl;

  /// 每次切换登录态（登录/登出/切地址/refresh）后必须重新注入，避免持有过期 token。
  void setAccessToken(String? token) {
    _cachedAccessToken = token;
  }

  String? get accessToken => _cachedAccessToken;

  void _updateBaseUrl() {
    final config = env;
    if (config != null) _dio.options.baseUrl = config.apiPrefix;
  }

  void setOnSessionExpired(OnSessionExpired callback) {
    _onSessionExpired = callback;
  }

  /// 暴露给 Repository 调用的统一 GET/POST/PUT/DELETE 入口。
  Future<T> request<T>({
    required String method,
    required String path,
    Object? body,
    Map<String, dynamic>? query,
    ApiDataParser<T>? parseData,
  }) async {
    try {
      final response = await _dio.request<dynamic>(
        path,
        data: body,
        queryParameters: query,
        options: Options(method: method),
      );
      return _decode(response, parseData ?? _defaultParser<T>());
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  Future<T> get<T>(
    String path, {
    Map<String, dynamic>? query,
    ApiDataParser<T>? parseData,
  }) {
    return request(
      method: 'GET',
      path: path,
      query: query,
      parseData: parseData,
    );
  }

  Future<T> post<T>(
    String path, {
    Object? body,
    Map<String, dynamic>? query,
    ApiDataParser<T>? parseData,
  }) {
    return request(
      method: 'POST',
      path: path,
      body: body,
      query: query,
      parseData: parseData,
    );
  }

  Future<T> put<T>(
    String path, {
    Object? body,
    Map<String, dynamic>? query,
    ApiDataParser<T>? parseData,
  }) {
    return request(
      method: 'PUT',
      path: path,
      body: body,
      query: query,
      parseData: parseData,
    );
  }

  Future<T> delete<T>(
    String path, {
    Object? body,
    Map<String, dynamic>? query,
    ApiDataParser<T>? parseData,
  }) {
    return request(
      method: 'DELETE',
      path: path,
      body: body,
      query: query,
      parseData: parseData,
    );
  }

  Future<T> patch<T>(
    String path, {
    Object? body,
    Map<String, dynamic>? query,
    ApiDataParser<T>? parseData,
  }) {
    return request(
      method: 'PATCH',
      path: path,
      body: body,
      query: query,
      parseData: parseData,
    );
  }

  /// multipart 上传专用：自动设置 Content-Type 为 multipart/form-data。
  Future<T> upload<T>({
    required String path,
    required FormData formData,
    Map<String, dynamic>? query,
    ApiDataParser<T>? parseData,
  }) async {
    try {
      final response = await _dio.post<dynamic>(
        path,
        data: formData,
        queryParameters: query,
      );
      return _decode(response, parseData ?? _defaultParser<T>());
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  /// refresh 专用：不经 401 拦截器（避免递归）。
  Future<bool> refreshAccessToken() async {
    final inFlight = _refreshing;
    if (inFlight != null) return inFlight.future;

    final completer = Completer<bool>();
    _refreshing = completer;
    try {
      final refreshToken = await tokenStorage.readRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) {
        completer.complete(false);
        return false;
      }
      final response = await _dio.post<dynamic>(
        '/auth/refresh',
        data: {'refreshToken': refreshToken},
        options: Options(
          method: 'POST',
          headers: {'Authorization': null},
          extra: {'__skipAuth': true},
        ),
      );
      final envelope = ApiEnvelope<Map<String, dynamic>>.fromJson(
        _asJsonObject(response.data),
        (raw) => _asJsonObject(raw),
      );
      if (!envelope.isOk || envelope.data == null) {
        completer.complete(false);
        return false;
      }
      final access = envelope.data!['AccessToken'] as String?;
      final refresh = envelope.data!['RefreshToken'] as String?;
      if (access == null || refresh == null) {
        completer.complete(false);
        return false;
      }
      await tokenStorage.write(accessToken: access, refreshToken: refresh);
      _cachedAccessToken = access;
      completer.complete(true);
      return true;
    } on DioException {
      completer.complete(false);
      return false;
    } catch (_) {
      completer.complete(false);
      return false;
    } finally {
      _refreshing = null;
    }
  }

  T _decode<T>(Response<dynamic> response, ApiDataParser<T> parseData) {
    final raw = response.data;
    if (raw is! Map<String, dynamic>) {
      throw ApiException(-1, '响应不是合法 JSON 对象');
    }
    final envelope = ApiEnvelope<T>.fromJson(raw, parseData);
    if (!envelope.isOk) {
      throw ApiException(envelope.code, envelope.msg);
    }
    final data = envelope.data;
    if (data == null) {
      return parseData(null);
    }
    return data;
  }

  ApiDataParser<T> _defaultParser<T>() {
    return (raw) {
      if (T == Map<String, dynamic>) {
        return _asJsonObject(raw) as T;
      }
      return raw as T;
    };
  }

  Never _mapDioError(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.connectionError) {
      throw NetworkException(e.message ?? '网络异常');
    }
    if (e.response != null) {
      final status = e.response!.statusCode ?? 0;
      final body = _tryJsonObject(e.response!.data);
      if (body != null) {
        final code = (body['Code'] as num?)?.toInt() ?? status;
        final msg = (body['Msg'] ?? '').toString().trim();
        throw ApiException(code, msg.isEmpty ? '请求失败' : msg);
      }
    }
    throw NetworkException(e.message ?? '请求失败');
  }

  Map<String, dynamic>? _tryJsonObject(dynamic raw) {
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return raw.cast<String, dynamic>();
    return null;
  }

  Map<String, dynamic> _asJsonObject(dynamic raw) {
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return raw.cast<String, dynamic>();
    if (raw == null) return const {};
    throw ApiException(-1, '响应不是 JSON 对象');
  }

  Future<void> notifySessionExpired() async {
    final cb = _onSessionExpired;
    if (cb != null) await cb();
  }

  static String _apiPrefix(String baseUrl) {
    final trimmed = baseUrl.trim().replaceFirst(RegExp(r'/+$'), '');
    return trimmed.endsWith('/api/v1') ? trimmed : '$trimmed/api/v1';
  }
}

class _AuthInterceptor extends Interceptor {
  _AuthInterceptor(this._client);
  final ApiClient _client;

  static const _authFree = {'/auth/register', '/auth/login', '/auth/refresh'};

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (options.extra['__skipAuth'] == true) {
      options.headers.remove('Authorization');
      handler.next(options);
      return;
    }
    if (_authFree.contains(options.path)) {
      options.headers.remove('Authorization');
      handler.next(options);
      return;
    }
    final token = _client.accessToken;
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final response = err.response;
    if (response == null) {
      return handler.next(err);
    }
    if (response.statusCode != 401) {
      return handler.next(err);
    }
    final path = err.requestOptions.path;
    if (_authFree.contains(path) ||
        err.requestOptions.extra['__skipAuth'] == true ||
        err.requestOptions.extra['__retried'] == true) {
      return handler.next(err);
    }
    final refreshed = await _client.refreshAccessToken();
    if (!refreshed) {
      await _client.notifySessionExpired();
      return handler.next(err);
    }
    try {
      final retryOptions = Options(
        method: err.requestOptions.method,
        headers: {
          ...err.requestOptions.headers,
          'Authorization': 'Bearer ${_client.accessToken}',
        },
        contentType: err.requestOptions.contentType,
        responseType: err.requestOptions.responseType,
        extra: {...err.requestOptions.extra, '__retried': true},
      );
      final retried = await _client.dio.request<dynamic>(
        err.requestOptions.path,
        data: err.requestOptions.data,
        queryParameters: err.requestOptions.queryParameters,
        options: retryOptions,
      );
      handler.resolve(retried);
    } on DioException catch (e) {
      handler.next(e);
    }
  }
}
