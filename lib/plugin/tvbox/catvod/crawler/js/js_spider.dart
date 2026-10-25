import 'dart:convert';

import 'package:PiliPlus/plugin/tvbox/catvod/crawler/js/helper/js_isolate.dart';
import 'package:PiliPlus/plugin/tvbox/catvod/crawler/spider.dart';

/// com.github.catvod.crawler.js.JsSpider
class JsSpider implements Spider {
  final String key;
  final String api;
  final String? ext;

  /// com.github.tvbox.osc.bean.SourceBean.getPlayTimeoutSeconds+timeoutSeconds
  int timeoutSeconds;

  JsSpider({
    required this.key,
    required this.api,
    this.ext,
    required this.timeoutSeconds,
  });

  Future<void> init() async {
    final r = await JsIsolate.instance.command('ensure', {
      'siteKey': key,
      'api': api,
      'ext': ext,
    });
    if (r['ok'] != true) throw Exception(r['error']);
  }

  static String _asBody(dynamic result) {
    if (result == null) return '';
    if (result is String) return result;
    try {
      return jsonEncode(result);
    } catch (_) {
      return '';
    }
  }

  Future<dynamic> _call(
    String method,
    List<dynamic> args, {
    Duration timeout = const Duration(seconds: 30),
  }) async {
    final r = await JsIsolate.instance.command('call', {
      'siteKey': key,
      'method': method,
      'args': args,
    }, timeout: timeout);
    if (r['ok'] != true) throw Exception(r['error']);
    return r['data'];
  }

  @override
  Future<String> homeContent(bool filter) async =>
      _asBody(await _call('home', [filter]));

  @override
  Future<String> homeVideoContent() async => _asBody(
    await _call('homeVod', const [], timeout: const Duration(seconds: 20)),
  );

  @override
  Future<String> categoryContent(
    String tid,
    String pg,
    bool filter,
    Map<String, String>? extend,
  ) async => _asBody(
    await _call(
      'category',
      [tid, pg, true, extend ?? const {}],
      timeout: Duration(seconds: timeoutSeconds),
    ),
  );

  @override
  Future<String> detailContent(List<String> ids) async => _asBody(
    await _call(
      'detail',
      [ids.isEmpty ? '' : ids.first],
      timeout: Duration(seconds: timeoutSeconds),
    ),
  );

  @override
  Future<String> searchContent(String key, bool quick, [String? pg]) async =>
      _asBody(
        await _call(
          'search',
          [key, quick, 1],
          timeout: const Duration(seconds: 20),
        ),
      );

  @override
  Future<String> playerContent(
    String flag,
    String id,
    List<String> vipFlags,
  ) async => _asBody(
    await _call(
      'play',
      [flag, id, vipFlags],
      timeout: Duration(seconds: timeoutSeconds),
    ),
  );

  @override
  Future<bool> isVideoFormat(String url) async {
    try {
      final result = await _call(
        'isVideo',
        [url],
        timeout: const Duration(seconds: 5),
      );
      return result == true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> manualVideoCheck() async {
    try {
      final result = await _call(
        'sniffer',
        const [],
        timeout: const Duration(seconds: 5),
      );
      return result == true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<Object?> proxyLocal(Map<String, String> params) => _call(
    'proxy',
    [params],
    timeout: const Duration(seconds: 15),
  );

  @override
  Future<void> destroy() async {}
}
