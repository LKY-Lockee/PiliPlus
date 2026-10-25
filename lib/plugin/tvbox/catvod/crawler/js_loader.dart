import 'package:PiliPlus/plugin/tvbox/catvod/crawler/js/helper/js_isolate.dart';
import 'package:PiliPlus/plugin/tvbox/catvod/crawler/js/js_spider.dart';
import 'package:PiliPlus/plugin/tvbox/catvod/crawler/spider.dart';
import 'package:PiliPlus/plugin/tvbox/catvod/crawler/spider_null.dart';
import 'package:PiliPlus/plugin/tvbox/catvod/proxy.dart';
import 'package:PiliPlus/plugin/tvbox/tvbox/osc/server/control_manager.dart';

/// com.github.catvod.crawler.JsLoader
class JsLoader {
  final Map<String, Spider> _spiders = {};

  static final JsLoader instance = JsLoader._();

  JsLoader._();

  /// com.github.catvod.crawler.JsLoader.getSpider
  Future<Spider> getSpider(
    String key,
    String api,
    String? ext, {
    int timeoutSeconds = 15,
  }) async {
    final cached = _spiders[key];
    if (cached != null) {
      if (cached is JsSpider) {
        cached.timeoutSeconds = timeoutSeconds;
      }
      return cached;
    }
    try {
      await ControlManager.instance.ensureServer(onProxy: proxyInvoke);
      await JsIsolate.instance.ensureStarted(proxyBase: Proxy.getUrl());
      final spider = JsSpider(
        key: key,
        api: api,
        ext: ext,
        timeoutSeconds: timeoutSeconds,
      );
      await spider.init();
      _spiders[key] = spider;
      return spider;
    } catch (_) {
      return SpiderNull();
    }
  }

  /// com.github.catvod.crawler.JsLoader.proxyInvoke
  Future<Object?> proxyInvoke(Map<String, String> params) async {
    final r = await JsIsolate.instance.command('proxy', {
      'siteKey': params['siteKey'] ?? '',
      'params': params,
    }, timeout: const Duration(seconds: 15));
    if (r['ok'] != true) throw Exception(r['error']);
    return r['data'];
  }
}
