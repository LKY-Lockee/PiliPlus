import 'dart:convert';
import 'dart:io';

import 'package:PiliPlus/http/loading_state.dart';
import 'package:PiliPlus/plugin/ugreen/http/ugreen_api.dart';
import 'package:PiliPlus/plugin/ugreen/http/ugreen_constants.dart';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';

abstract final class UgreenClient {
  static final Dio dio =
      Dio(
          BaseOptions(
            connectTimeout: const Duration(seconds: 20),
            receiveTimeout: const Duration(seconds: 30),
            sendTimeout: const Duration(seconds: 20),
            validateStatus: (status) => status != null,
          ),
        )
        ..httpClientAdapter = IOHttpClientAdapter(
          createHttpClient: () => HttpClient()
            ..idleTimeout = const Duration(seconds: 15)
            ..badCertificateCallback = (cert, host, port) => true,
        );

  static Map<String, String> headers(String? clientId) => {
    'UG-Agent': 'PC/WEB',
    if (clientId != null && clientId.isNotEmpty) ...{
      'Client-Id': clientId,
      'UG-Client-Id': clientId,
    },
    'Client-Version': UgreenHttpString.clientVersion,
    'Client-Version-Str': UgreenHttpString.clientVersionStr,
    'Cache-Control': 'no-cache',
    'X-Specify-Language': UgreenHttpString.language,
    'User-Feature': 'Windows',
    'Accept': 'application/json, text/plain, */*',
  };

  static Map<String, dynamic>? asJson(dynamic data) {
    if (data is Map) {
      return data.cast<String, dynamic>();
    }
    if (data is String && data.isNotEmpty) {
      try {
        final json = jsonDecode(data);
        return json is Map ? json.cast<String, dynamic>() : null;
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  static int? toInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }

  static bool toBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    final str = value?.toString().toLowerCase();
    return str == 'true' || str == '1';
  }

  static List<String> toStringList(dynamic value) {
    if (value is List) {
      return value
          .map((e) => e?.toString() ?? '')
          .where((e) => e.isNotEmpty)
          .toList();
    }
    final str = value?.toString();
    return str == null || str.isEmpty ? const [] : [str];
  }

  static Future<LoadingState<Map<String, dynamic>>> request(
    String baseUrl,
    String path, {
    String method = 'GET',
    Map<String, dynamic>? query,
    Map<String, dynamic>? data,
    String? token,
    String? clientId,
  }) async {
    final params = <String, String>{
      if (query != null)
        for (final entry in query.entries) entry.key: '${entry.value}',
      if (token != null && token.isNotEmpty) 'token': token,
    };
    final uri = Uri.parse('$baseUrl/ugreen/$path');
    final requestUri = params.isEmpty
        ? uri
        : uri.replace(queryParameters: params);
    try {
      final response = await dio.request<dynamic>(
        requestUri.toString(),
        data: method == 'POST' ? (data ?? const <String, dynamic>{}) : null,
        options: Options(
          method: method,
          headers: headers(clientId),
          contentType: method == 'POST' ? Headers.jsonContentType : null,
        ),
      );
      final json = asJson(response.data);
      if (json == null) {
        return Error('服务返回异常（HTTP ${response.statusCode ?? '未知'}）');
      }
      final code = toInt(json['code']);
      if (code != null && code != 200) {
        return Error(json['msg']?.toString() ?? '操作失败', code: code);
      }
      return Success(json);
    } on DioException catch (e) {
      return Error(dioError(e));
    }
  }

  static Future<bool> probe(
    String baseUrl, {
    required String clientId,
  }) async {
    try {
      final response = await dio.get<dynamic>(
        '$baseUrl/ugreen/${UgreenApi.verifyRunning}',
        options: Options(
          headers: headers(clientId),
          receiveTimeout: const Duration(seconds: 5),
          sendTimeout: const Duration(seconds: 5),
        ),
      );
      final json = asJson(response.data);
      if (json == null) {
        return false;
      }
      final data = json['data'];
      return toBool(json['running'] ?? (data is Map ? data['running'] : null));
    } catch (_) {
      return false;
    }
  }

  static String dioError(DioException e) {
    return switch (e.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout => '连接设备超时',
      DioExceptionType.connectionError => '无法连接设备',
      DioExceptionType.badResponse =>
        '服务响应异常（HTTP ${e.response?.statusCode ?? '未知'}）',
      _ => e.message ?? '网络请求失败',
    };
  }

  static String get systemName {
    if (Platform.isWindows) return 'windows';
    if (Platform.isMacOS) return 'macos';
    if (Platform.isLinux) return 'linux';
    if (Platform.isAndroid) return 'android';
    if (Platform.isIOS) return 'ios';
    return 'unknown';
  }

  static String get deviceName {
    try {
      return Platform.localHostname;
    } catch (_) {
      return 'PC';
    }
  }

  static String get deviceAlias => deviceName;

  static String get deviceOsVersion {
    try {
      final version = Platform.operatingSystemVersion;
      return version.isEmpty ? 'Windows 11' : version;
    } catch (_) {
      return 'Windows 11';
    }
  }
}
