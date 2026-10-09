import 'dart:async';
import 'dart:convert';

import 'package:PiliPlus/plugin/tvbox/catvod/crawler/js/async.dart';
import 'package:PiliPlus/plugin/tvbox/catvod/crawler/js/global.dart';
import 'package:PiliPlus/plugin/tvbox/catvod/crawler/js/helper/js_worker.dart';
import 'package:PiliPlus/plugin/tvbox/catvod/crawler/js/module_loader.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_js/flutter_js.dart';
import 'package:synchronized/synchronized.dart';

/// com.github.catvod.crawler.js.JsSpider
class JsSpider {
  final WorkerHost host;
  final Map<String, String> modules = {};

  /// com.github.catvod.crawler.js.JsSpider.ctx
  QuickJsRuntime2? _runtime;

  JSInvokable? _setGlobal;
  final Set<String> _spiderKeys = {};
  final Lock _lock = Lock();
  String? _missingModule;

  static const engineInterruptMs = 60000;

  JSInvokable? get setGlobalFn => _setGlobal;

  JsSpider(this.host);

  String _wrapIfNeeded(String name, String src) {
    final base = name.startsWith('./') ? name.substring(2) : name;
    if (base.split('/').last == 'crypto-js.js' &&
        !src.startsWith('var module')) {
      return JsModules.wrapCryptoJs(src);
    }
    return src;
  }

  String _handleModule(String name) {
    final src = JsModules.lookup(modules, name);
    if (src != null) {
      if (JsModules.isInvalidModuleContent(src)) {
        return JsModules.emptyModuleSource;
      }
      return _wrapIfNeeded(name, src);
    }
    final fetched = JsModules.onFetchSync?.call(name);
    if (fetched == null) {
      _missingModule = name;
      throw JSError('Module Not found: $name');
    }
    if (JsModules.isInvalidModuleContent(fetched)) {
      JsModules.register(modules, name, JsModules.emptyModuleSource);
      return JsModules.emptyModuleSource;
    }
    JsModules.register(modules, name, fetched);
    return _wrapIfNeeded(name, fetched);
  }

  /// com.github.catvod.crawler.js.JsSpider.init
  Future<void> _initLocked() async {
    if (_runtime != null) return;
    final rt = QuickJsRuntime2(
      moduleHandler: _handleModule,
      timeout: engineInterruptMs,
    );
    _runtime = rt;
    JsModules.onFetchSync = host.fetchModuleSync;
    modules.addAll(host.builtin);
    final global = rt.evaluate('(key, val) => { this[key] = val; }');
    _setGlobal = global.rawResult as JSInvokable?;
    await Global.install(this, host);
    rt
      ..evaluate(host.builtin['crypto-js.js']!, name: 'crypto-js.js')
      ..evaluate(
        "import tpl from '模板.js'; globalThis.muban = tpl.muban;"
        ' globalThis.getMubans = tpl.getMubans;',
        name: 'muban_bootstrap',
        evalFlags: JSEvalFlag.MODULE,
      );
    kick();
  }

  /// com.github.catvod.crawler.js.JsSpider.initializeJS
  Future<void> _ensureSpiderLocked(
    String siteKey,
    String api,
    String? ext,
  ) async {
    await _initLocked();
    if (_spiderKeys.contains(siteKey)) return;
    final source = host.fetchModuleSync(api);
    if (source == null) {
      throw Exception('js 源加载失败: $api');
    }
    final code = source.replaceFirst(
      RegExp(r'__JS_SPIDER__\s*='),
      'export default ',
    );
    modules[api] = code;
    await _evalModuleWithRecovery(code, name: api, baseUrl: api);
    final globalName = spiderGlobal(siteKey);
    final bootstrap =
        '''
import * as spider from ${jsonEncode(api)};
(() => {
  let sp = null;
  if (spider.__jsEvalReturn) {
    globalThis.req = http;
    sp = spider.__jsEvalReturn();
    sp.is_cat = true;
  } else if (spider.default) {
    sp = typeof spider.default === 'function' ? spider.default() : spider.default;
  }
  if (sp && sp.init) {
    let extArg = ${jsonEncode(ext ?? '')};
    try { extArg = JSON.parse(extArg); } catch (e) {}
    if (sp.is_cat) {
      sp.init({ stype: 3, skey: ${jsonEncode(siteKey)}, ext: extArg });
    } else {
      sp.init(extArg);
    }
  }
  globalThis.$globalName = sp;
})();
''';
    await _evalModuleWithRecovery(
      bootstrap,
      name: 'bootstrap_${siteKey.hashCode.abs()}',
      baseUrl: api,
    );
    kick();
    _spiderKeys.add(siteKey);
  }

  Future<void> _evalModuleWithRecovery(
    String code, {
    required String name,
    required String baseUrl,
  }) async {
    final rt = _runtime!;
    for (var attempt = 0; attempt < 8; attempt++) {
      _missingModule = null;
      final res = rt.evaluate(code, name: name, evalFlags: JSEvalFlag.MODULE);
      if (!res.isError) {
        return;
      }
      final message = res.stringResult;
      final missing = _missingModule;
      if (missing == null || modules.containsKey(missing)) {
        throw Exception(message);
      }
      final url = missing.startsWith('http')
          ? missing
          : (Uri.tryParse(baseUrl)?.resolve(missing).toString() ?? missing);
      final src = host.fetchModuleSync(url);
      if (src == null || JsModules.isInvalidModuleContent(src)) {
        JsModules.register(modules, url, JsModules.emptyModuleSource);
        JsModules.register(modules, missing, JsModules.emptyModuleSource);
        continue;
      }
      JsModules.register(modules, url, src);
    }
    throw Exception('js 模块加载失败: $name');
  }

  /// com.github.catvod.crawler.js.JsSpider.proxy2
  Future<dynamic> _callProxy2(
    String siteKey,
    Map<String, String> params,
  ) async {
    final url = params['url'] ?? '';
    dynamic header;
    final rawHeader = params['header'];
    if (rawHeader != null && rawHeader.isNotEmpty) {
      try {
        header = jsonDecode(rawHeader);
      } catch (_) {
        header = const {};
      }
    } else {
      header = const {};
    }
    final result = await callMethod(
      siteKey,
      'proxy',
      [url.split('/'), header],
      timeout: const Duration(seconds: 15),
    );
    Map<String, dynamic> res;
    if (result is Map) {
      res = result.cast<String, dynamic>();
    } else if (result is String && result.isNotEmpty) {
      final decoded = jsonDecode(result);
      res = decoded is Map
          ? decoded.cast<String, dynamic>()
          : <String, dynamic>{};
    } else {
      res = <String, dynamic>{};
    }
    var contentType = 'application/octet-stream';
    final headers = res['headers'];
    if (headers is Map) {
      final ct = headers['Content-Type'] ?? headers['content-type'];
      if (ct != null && ct.toString().isNotEmpty) contentType = ct.toString();
    }
    final content = res['content']?.toString() ?? '';
    final buffer = res['buffer'] is num ? (res['buffer'] as num).toInt() : 0;
    final bytes = buffer == 2 ? base64.decode(content) : utf8.encode(content);
    return <dynamic>[200, contentType, bytes];
  }

  QuickJsRuntime2 requireRuntime() {
    final rt = _runtime;
    if (rt == null) {
      throw StateError('js engine not ready');
    }
    return rt;
  }

  void kick() {
    try {
      _runtime?.dispatch();
    } catch (_) {}
  }

  String spiderGlobal(String siteKey) {
    final digest = md5.convert(utf8.encode(siteKey)).toString();
    return 'J$digest';
  }

  Future<void> ensureSpider({
    required String siteKey,
    required String api,
    String? ext,
  }) {
    return _lock.synchronized(() => _ensureSpiderLocked(siteKey, api, ext));
  }

  /// com.github.catvod.crawler.js.JsSpider.call
  Future<dynamic> callMethod(
    String siteKey,
    String method,
    List<dynamic> args, {
    Duration timeout = const Duration(seconds: 30),
  }) {
    return _lock.synchronized(() {
      final rt = _runtime;
      if (rt == null || !_spiderKeys.contains(siteKey)) {
        throw StateError('spider not loaded: $siteKey');
      }
      final globalName = spiderGlobal(siteKey);
      final fn = rt
          .evaluate('globalThis.$globalName && globalThis.$globalName.$method')
          .rawResult;
      if (fn is! JSInvokable) return null;
      return Async.run(kick, fn.invoke(args)).timeout(timeout);
    });
  }

  Future<dynamic> callProxy(String siteKey, Map<String, String> params) {
    if (params['from'] == 'catvod') return _callProxy2(siteKey, params);
    return callMethod(
      siteKey,
      'proxy',
      [params],
      timeout: const Duration(seconds: 15),
    );
  }

  /// com.github.catvod.crawler.JsLoader.clear
  Future<void> dispose() {
    return _lock.synchronized(() {
      final rt = _runtime;
      _runtime = null;
      _setGlobal = null;
      _spiderKeys.clear();
      try {
        rt?.dispose();
      } catch (_) {}
    });
  }
}
