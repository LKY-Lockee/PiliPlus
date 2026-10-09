import 'package:dio/dio.dart';

/// com.github.catvod.net.OkHttp
class Http {
  /// com.github.tvbox.osc.util.OkGoHelper.getDefaultClient+client
  static late final Dio client;

  Http._();

  /// com.github.catvod.net.OkHttp.string
  static Future<String?> string(
    String url, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    final res = await get(
      url,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
    );
    return res.data;
  }

  static Future<Response<String>> get(
    String url, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      return await client.get<String>(
        url,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      return Response(
        data: null,
        statusCode: e.response?.statusCode ?? -1,
        requestOptions: e.requestOptions,
      );
    }
  }

  static Future<Response<String>> getUri(
    Uri uri, {
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      return await client.getUri<String>(
        uri,
        options: options,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      return Response(
        data: null,
        statusCode: e.response?.statusCode ?? -1,
        requestOptions: e.requestOptions,
      );
    }
  }

  /// com.github.catvod.net.OkHttp.newCall
  static Future<Response<List<int>>> requestBytes(
    String url, {
    String method = 'GET',
    Map<String, dynamic>? headers,
    Object? body,
    int timeoutMs = 10000,
    bool followRedirects = true,
  }) async {
    final options = Options(
      method: method,
      headers: headers,
      responseType: ResponseType.bytes,
      connectTimeout: Duration(milliseconds: timeoutMs),
      sendTimeout: Duration(milliseconds: timeoutMs),
      receiveTimeout: Duration(milliseconds: timeoutMs),
      followRedirects: followRedirects,
    );
    try {
      return await client.request<List<int>>(url, data: body, options: options);
    } on DioException catch (e) {
      return Response(
        data: null,
        statusCode: e.response?.statusCode ?? -1,
        requestOptions: e.requestOptions,
      );
    }
  }
}
