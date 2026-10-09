import 'dart:convert';
import 'dart:typed_data';

import 'package:PiliPlus/plugin/tvbox/catvod/net/http.dart';
import 'package:PiliPlus/plugin/tvbox/tvbox/osc/util/charset_utils.dart';
import 'package:dio/dio.dart';

/// com.github.catvod.crawler.js.Connect
class Connect {
  Connect._();

  /// com.github.catvod.crawler.js.Connect.to
  static Future<Map<String, dynamic>> to(
    String url,
    Map<String, dynamic> opts,
  ) async {
    var method = 'GET';
    final m = opts['method'];
    if (m is String && m.isNotEmpty) {
      method = m.toUpperCase();
      if (method == 'HEADER') method = 'HEAD';
    }
    final headers = <String, dynamic>{};
    final rawHeaders = opts['headers'];
    if (rawHeaders is Map) {
      rawHeaders.forEach((k, v) => headers[k.toString()] = v.toString());
    }
    Object? body = opts['body'];
    if (body != null && body.toString().isNotEmpty) {
      body = body.toString();
    }
    final data = opts['data'];
    if (data != null && method != 'GET' && method != 'HEAD') {
      final postType = opts['postType']?.toString() ?? 'json';
      if (data is Map) {
        if (postType == 'form') {
          headers['Content-Type'] ??= 'application/x-www-form-urlencoded';
          body = data.entries
              .map(
                (e) =>
                    '${Uri.encodeQueryComponent(e.key.toString())}=${Uri.encodeQueryComponent(e.value.toString())}',
              )
              .join('&');
        } else if (postType == 'form-data') {
          body = FormData.fromMap(
            data.map((k, v) => MapEntry(k.toString(), v)),
          );
        } else {
          headers['Content-Type'] ??= 'application/json';
          body = jsonEncode(data);
        }
      } else {
        headers['Content-Type'] ??= 'application/json';
        body = data.toString();
      }
    }
    final redirect = opts['redirect'] is num
        ? (opts['redirect'] as num).toInt()
        : 1;
    final timeoutMs = opts['timeout'] is num
        ? (opts['timeout'] as num).toInt()
        : 10000;
    final resp = await Http.requestBytes(
      url,
      method: method,
      headers: headers,
      body: body,
      timeoutMs: timeoutMs,
      followRedirects: redirect != 0,
    );
    final respHeaders = <String, dynamic>{};
    resp.headers.forEach((k, v) {
      if (v.length == 1) {
        respHeaders[k] = v.first;
      } else if (v.length >= 2) {
        respHeaders[k] = List<String>.from(v);
      }
    });
    final reqCt = headers['Content-Type']?.toString();
    final respCt = respHeaders['content-type'];
    final contentType = reqCt?.isNotEmpty == true
        ? reqCt
        : (respCt is List
              ? (respCt.isEmpty ? null : respCt.first)
              : respCt as String?);
    final bytes = resp.data;
    dynamic content;
    if (opts['buffer'] == 1) {
      content = bytes == null ? <int>[] : Uint8List.fromList(bytes);
    } else if (opts['buffer'] == 2) {
      content = bytes == null ? '' : base64Encode(bytes);
    } else {
      content = bytes == null
          ? ''
          : CharsetUtils.decodeBytes(bytes, contentType);
    }
    return {'headers': respHeaders, 'content': content};
  }
}
