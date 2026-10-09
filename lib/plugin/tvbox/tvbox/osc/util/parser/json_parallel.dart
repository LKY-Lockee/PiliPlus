import 'dart:async';
import 'dart:convert';

import 'package:PiliPlus/plugin/tvbox/catvod/net/http.dart';
import 'package:PiliPlus/plugin/tvbox/tvbox/osc/bean/parse_bean.dart';
import 'package:PiliPlus/plugin/tvbox/tvbox/osc/util/parser/utils.dart';
import 'package:PiliPlus/plugin/tvbox/tvbox/osc/util/string_utils.dart';
import 'package:dio/dio.dart';

/// com.github.tvbox.osc.util.parser.JsonParallel
class JsonParallel {
  JsonParallel._();

  /// com.github.tvbox.osc.util.parser.JsonParallel.parse
  static Future<({String url, Map<String, String> headers})?> _requestJson(
    ParseBean parse,
    String videoUrl,
  ) async {
    final (realUrl, catHeaders) = parseCatExt(parse.mixUrl());
    final requestUrl = '$realUrl${StringUtils.javaUrlEncode(videoUrl)}';
    final resp = await Http.get(
      requestUrl,
      options: Options(
        responseType: ResponseType.plain,
        connectTimeout: const Duration(seconds: 8),
        receiveTimeout: const Duration(seconds: 8),
        sendTimeout: const Duration(seconds: 8),
      ),
    );
    final data = resp.data;
    if (data == null) return null;
    final parsed = Utils.jsonParse(videoUrl, data);
    if (parsed == null) return null;
    return (url: parsed.url, headers: {...catHeaders, ...parsed.headers});
  }

  /// com.github.tvbox.osc.util.parser.JsonParallel.getReqHeader
  static (String, Map<String, String>) parseCatExt(String url) {
    final start = url.indexOf('cat_ext=');
    if (start < 0) return (url, const {});
    final end = url.indexOf('&', start);
    if (end < 0) return (url, const {});
    try {
      final ext = base64Url.decode(
        base64Url.normalize(url.substring(start + 8, end)),
      );
      final json = jsonDecode(utf8.decode(ext));
      final headers = <String, String>{};
      if (json is Map) {
        final header = json['header'];
        if (header is Map) {
          header.forEach((k, v) => headers[k.toString()] = v?.toString() ?? '');
        }
      }
      final stripped = url.substring(0, start) + url.substring(end + 1);
      return (stripped, headers);
    } catch (_) {
      return (url, const {});
    }
  }

  static Map<String, String> getReqHeader(String url) => parseCatExt(url).$2;

  /// com.github.tvbox.osc.util.parser.JsonParallel.parse
  static Future<({String url, Map<String, String> headers})?> parse(
    List<ParseBean> parses,
    String videoUrl,
  ) {
    final completer = Completer<({String url, Map<String, String> headers})?>();
    var remaining = parses.length;
    for (final parse in parses) {
      _requestJson(parse, videoUrl).then(
        (hit) {
          if (hit != null && !completer.isCompleted) {
            completer.complete(hit);
          }
          remaining--;
          if (remaining <= 0 && !completer.isCompleted) {
            completer.complete(null);
          }
        },
        onError: (_) {
          remaining--;
          if (remaining <= 0 && !completer.isCompleted) {
            completer.complete(null);
          }
        },
      );
    }
    return completer.future.timeout(
      const Duration(seconds: 12),
      onTimeout: () => null,
    );
  }
}
