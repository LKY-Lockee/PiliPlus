import 'dart:async';

import 'package:PiliPlus/plugin/tvbox/catvod/crawler/python/python_loader.dart';
import 'package:PiliPlus/plugin/tvbox/catvod/crawler/python/python_spider.dart';
import 'package:PiliPlus/plugin/tvbox/catvod/crawler/spider.dart';
import 'package:PiliPlus/plugin/tvbox/catvod/crawler/spider_null.dart';
import 'package:PiliPlus/plugin/tvbox/tvbox/osc/server/control_manager.dart';

/// com.github.catvod.crawler.pyLoader
class PyLoader {
  final Map<String, Spider> _spiders = {};

  static final PyLoader instance = PyLoader._();

  /// com.github.tvbox.osc.api.ApiConfig.currentPyKey
  String _currentKey = '';

  PyLoader._();

  void setRecentPyKey(String key) => _currentKey = key;

  /// com.github.catvod.crawler.pyLoader.getSpider
  Future<Spider> getSpider(
    String key,
    String api,
    String? ext, {
    int timeoutSeconds = 15,
  }) async {
    setRecentPyKey(key);
    final cached = _spiders[key];
    if (cached != null) {
      if (cached is PythonSpider) {
        cached.timeoutSeconds = timeoutSeconds;
      }
      return cached;
    }
    try {
      await ControlManager.instance.ensureServer(
        onProxy: proxyInvoke,
        engine: 'py',
      );
      final spider = PythonSpider(
        key: key,
        timeoutSeconds: timeoutSeconds,
      );
      await spider.init(api, ext ?? '');
      _spiders[key] = spider;
      return spider;
    } catch (_) {
      return SpiderNull();
    }
  }

  /// com.github.catvod.crawler.pyLoader.proxyInvoke
  Future<Object?> proxyInvoke(Map<String, String> params) async {
    var siteKey = params['siteKey'] ?? '';
    final cut = siteKey.indexOf(RegExp('[?&]'));
    if (cut > 0) {
      siteKey = siteKey.substring(0, cut);
    }
    if (siteKey.isEmpty) {
      siteKey = _currentKey;
    }
    final r = await PythonLoader.instance.command('proxy', {
      'siteKey': siteKey,
      'params': params,
    }, timeout: null);
    if (r['ok'] != true) throw Exception(r['error']);
    return r['data'];
  }

  /// com.github.catvod.crawler.pyLoader.clear
  Future<void> clear() async {
    _spiders.clear();
    _currentKey = '';
    try {
      if (PythonLoader.instance.started) {
        await PythonLoader.instance.command(
          'clear',
          const {},
          timeout: const Duration(seconds: 10),
        );
      }
    } catch (_) {}
  }
}
